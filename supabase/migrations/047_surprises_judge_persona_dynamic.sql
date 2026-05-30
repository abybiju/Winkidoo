-- 047_surprises_judge_persona_dynamic.sql
-- Drop the hard-coded judge_persona CHECK on surprises.
--
-- Migration 001 constrained surprises.judge_persona to the 5 original personas
-- ('sassy_cupid', 'poetic_romantic', 'chaos_gremlin', 'the_ex', 'dr_love').
-- Since then the app added judge packs (migrations 024/027 — e.g.
-- 'bollywood_romance', 'horror_confession', 'beach_memories', ...) and the
-- custom judge builder (persona id 'custom'). Selecting any of those when
-- hiding a surprise tripped `surprises_judge_persona_check` with code 23514
-- ("new row for relation \"surprises\" violates check constraint").
--
-- Judge personas are now a dynamic set (DB-seeded packs + custom judges), so a
-- static enum CHECK is no longer correct. Validation lives in the app and the
-- judges/judge_pack_judges tables. Drop the constraint; keep NOT NULL.

alter table public.surprises
  drop constraint if exists surprises_judge_persona_check;
