-- Migration 021: Judge Collectible Cards
-- Run in Supabase Dashboard → SQL Editor

CREATE TABLE judge_collectibles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id uuid REFERENCES couples(id) ON DELETE CASCADE,
  judge_persona text NOT NULL,
  rarity text NOT NULL DEFAULT 'common', -- common/rare/legendary
  battle_id uuid REFERENCES surprises(id),
  seeker_score int,
  earned_at timestamptz DEFAULT now()
);

ALTER TABLE judge_collectibles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "couple members" ON judge_collectibles
  FOR ALL USING (couple_id IN (
    SELECT id FROM couples WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
  ));

CREATE INDEX judge_collectibles_couple_persona_idx
  ON judge_collectibles (couple_id, judge_persona);
