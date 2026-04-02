-- 036: Love Letters from the Future
-- Adds future_letter support to surprises.
-- future_letter_judge_persona: which judge persona to age for the rewrite

-- Update surprise_type check constraint to include 'future_letter'
alter table public.surprises drop constraint if exists surprises_surprise_type_check;
alter table public.surprises
  add constraint surprises_surprise_type_check
  check (surprise_type in ('text', 'photo', 'voice', 'future_letter'));

-- Column for the judge persona to use in the aged rewrite
alter table public.surprises
  add column if not exists future_letter_judge_persona text;
