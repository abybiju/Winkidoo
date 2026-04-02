-- 035: Surprise Roulette — spin a wheel instead of choosing difficulty
-- Adds roulette_result column to surprises.
-- Values: null (no roulette), 'pending' (wheel not yet spun),
--         'easy', 'medium', 'hard', 'chaos', 'golden'

alter table public.surprises
  add column if not exists roulette_result text
  check (roulette_result in ('pending', 'easy', 'medium', 'hard', 'chaos', 'golden'));
