-- Migration 018: Battle Pass — Monthly Seasonal Track
-- Run in Supabase Dashboard → SQL Editor

CREATE TABLE IF NOT EXISTS battle_pass_seasons (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name       text NOT NULL,
  start_date date NOT NULL,
  end_date   date NOT NULL,
  is_active  boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS battle_pass_progress (
  couple_id  uuid NOT NULL REFERENCES couples(id) ON DELETE CASCADE,
  season_id  uuid NOT NULL REFERENCES battle_pass_seasons(id) ON DELETE CASCADE,
  points     integer NOT NULL DEFAULT 0,
  tier       text NOT NULL DEFAULT 'bronze',
  PRIMARY KEY (couple_id, season_id)
);

ALTER TABLE battle_pass_seasons ENABLE ROW LEVEL SECURITY;
ALTER TABLE battle_pass_progress ENABLE ROW LEVEL SECURITY;

-- Seasons are publicly readable (everyone sees the current season)
CREATE POLICY "seasons are readable by all authenticated users"
  ON battle_pass_seasons FOR SELECT
  TO authenticated USING (true);

-- Progress is couple-scoped
CREATE POLICY "couple members can read and write own progress"
  ON battle_pass_progress FOR ALL
  USING (
    couple_id IN (
      SELECT id FROM couples
      WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
    )
  );

-- Seed the first season (update dates as needed)
INSERT INTO battle_pass_seasons (name, start_date, end_date, is_active)
VALUES ('Season 1: First Sparks', '2026-03-01', '2026-03-31', true)
ON CONFLICT DO NOTHING;
