-- Migration 017: Judge Memory — Persistent AI Personality
-- Run in Supabase Dashboard → SQL Editor

CREATE TABLE IF NOT EXISTS judge_memory (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id      uuid NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
  judge_persona  text NOT NULL,
  memory_summary text NOT NULL,
  created_at     timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS judge_memory_couple_persona_idx
  ON judge_memory (couple_id, judge_persona, created_at DESC);

ALTER TABLE judge_memory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "couple members can read and write own memories"
  ON judge_memory FOR ALL
  USING (
    couple_id IN (
      SELECT id FROM couples
      WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
    )
  );
