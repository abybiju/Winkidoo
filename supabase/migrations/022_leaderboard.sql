-- Migration 022: Leaderboard — public read policy on couple_xp
-- Run in Supabase Dashboard → SQL Editor

-- Allow anyone to read couple_xp for leaderboard purposes.
-- couple_id is a UUID so no PII is exposed.
CREATE POLICY "public leaderboard read" ON couple_xp
  FOR SELECT USING (true);
