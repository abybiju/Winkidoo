-- Migration 016: Couple XP / Love Levels
-- Run in Supabase Dashboard → SQL Editor

CREATE TABLE IF NOT EXISTS couple_xp (
  couple_id  uuid PRIMARY KEY REFERENCES couples(id) ON DELETE CASCADE,
  total_xp   integer NOT NULL DEFAULT 0,
  current_level integer NOT NULL DEFAULT 1,
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE couple_xp ENABLE ROW LEVEL SECURITY;

CREATE POLICY "couple members can read and write own xp"
  ON couple_xp FOR ALL
  USING (
    couple_id IN (
      SELECT id FROM couples
      WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
    )
  );
