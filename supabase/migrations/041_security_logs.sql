-- Security event logging table for monitoring auth attempts, API errors, suspicious activity.
create table if not exists public.security_logs (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  user_id uuid,
  details jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.security_logs enable row level security;

-- Users can insert their own logs
create policy "Users can insert own security logs"
  on public.security_logs for insert
  with check (user_id = auth.uid() or user_id is null);

-- Only service role can read (dashboard/admin queries only)
-- No SELECT policy for anon/authenticated — logs are write-only from client

-- Index for querying by event type and time
create index idx_security_logs_event_type on public.security_logs (event_type, created_at desc);
create index idx_security_logs_user_id on public.security_logs (user_id, created_at desc);
