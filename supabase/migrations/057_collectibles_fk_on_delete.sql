-- Migration 057: Fix judge_collectibles battle_id FK blocking surprise deletion
-- Run in Supabase Dashboard → SQL Editor
--
-- Migration 021 created judge_collectibles.battle_id REFERENCES surprises(id)
-- with no ON DELETE action (defaults to NO ACTION), so deleting a surprise
-- that earned a collectible fails with FK violation 23503.
-- Collectibles are earned trophies keyed by (couple_id, judge_persona);
-- battle_id is provenance only, so SET NULL keeps the card when the
-- surprise is deleted.

ALTER TABLE judge_collectibles
  DROP CONSTRAINT judge_collectibles_battle_id_fkey,
  ADD CONSTRAINT judge_collectibles_battle_id_fkey
    FOREIGN KEY (battle_id) REFERENCES surprises(id) ON DELETE SET NULL;
