-- Migration 042: Server-side rate limiting
-- Tracks API call counts per user/action with sliding windows.
-- Client-side rate limiter provides first line of defense;
-- this table enables server-side enforcement and abuse analytics.

CREATE TABLE IF NOT EXISTS rate_limit_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_rate_limit_user_action ON rate_limit_entries (user_id, action, created_at DESC);

-- Auto-cleanup: delete entries older than 24 hours (run via pg_cron or manual)
-- For now, the RPC handles window-based pruning on each check.

-- RPC: Check and record a rate-limited action.
-- Returns JSON: { "allowed": bool, "remaining": int, "wait_seconds": int }
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_user_id UUID,
  p_action TEXT,
  p_max_attempts INT,
  p_window_seconds INT
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_window_start TIMESTAMPTZ;
  v_count INT;
  v_remaining INT;
  v_oldest TIMESTAMPTZ;
  v_wait INT;
BEGIN
  v_window_start := now() - (p_window_seconds || ' seconds')::INTERVAL;

  -- Count attempts in the current window
  SELECT COUNT(*), MIN(created_at)
  INTO v_count, v_oldest
  FROM rate_limit_entries
  WHERE user_id = p_user_id
    AND action = p_action
    AND created_at > v_window_start;

  IF v_count >= p_max_attempts THEN
    -- Calculate wait time from oldest entry in window
    v_wait := GREATEST(0, EXTRACT(EPOCH FROM (v_oldest + (p_window_seconds || ' seconds')::INTERVAL - now()))::INT);
    v_remaining := 0;
    RETURN jsonb_build_object('allowed', false, 'remaining', 0, 'wait_seconds', v_wait);
  END IF;

  -- Record the attempt
  INSERT INTO rate_limit_entries (user_id, action) VALUES (p_user_id, p_action);

  v_remaining := p_max_attempts - v_count - 1;
  RETURN jsonb_build_object('allowed', true, 'remaining', v_remaining, 'wait_seconds', 0);
END;
$$;

-- Cleanup function: purge entries older than 24 hours
CREATE OR REPLACE FUNCTION cleanup_rate_limit_entries()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM rate_limit_entries WHERE created_at < now() - INTERVAL '24 hours';
END;
$$;

-- RLS: Users can only see/insert their own rate limit entries
ALTER TABLE rate_limit_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own rate limit entries"
  ON rate_limit_entries FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read own rate limit entries"
  ON rate_limit_entries FOR SELECT
  USING (auth.uid() = user_id);

-- Grant execute on the RPC to authenticated users
GRANT EXECUTE ON FUNCTION check_rate_limit TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_rate_limit_entries TO service_role;
