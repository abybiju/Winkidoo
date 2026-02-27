-- Data-driven judges: extend table with tagline, difficulty, chaos, tone_tags, preview_quotes,
-- primary_color_hex, created_at, is_premium; season_start/season_end as timestamptz for active query.
-- persona_id remains the stable key for surprises; we hide from selection when outside season, never delete.

-- New columns
alter table public.judges add column if not exists tagline text;
alter table public.judges add column if not exists difficulty_level int default 2;
alter table public.judges add column if not exists chaos_level int default 1;
alter table public.judges add column if not exists tone_tags text[] default '{}';
alter table public.judges add column if not exists preview_quotes text[] default '{}';
alter table public.judges add column if not exists primary_color_hex text;
alter table public.judges add column if not exists created_at timestamptz default now();
alter table public.judges add column if not exists is_premium boolean not null default false;

-- Season columns: date -> timestamptz (nullable)
alter table public.judges alter column season_start type timestamptz using season_start::timestamptz;
alter table public.judges alter column season_end type timestamptz using season_end::timestamptz;

-- Backfill is_premium from premium_flag, then drop premium_flag
update public.judges set is_premium = premium_flag where premium_flag is not null;
alter table public.judges drop column if exists premium_flag;

-- Permanent judges: clear season so they are always active (season_start/is null in query)
update public.judges set season_start = null, season_end = null;

-- Backfill UI/metadata from app seed (by persona_id)
update public.judges set
  tagline = 'Love is a battlefield.',
  difficulty_level = 2,
  chaos_level = 1,
  tone_tags = array['Romantic', 'Strict'],
  preview_quotes = array['Bring your A-game.', 'I''ve seen better.', 'Try again, sweetheart.'],
  primary_color_hex = 'FF6B9D'
where persona_id = 'sassy_cupid';

update public.judges set
  tagline = 'Where words become magic.',
  difficulty_level = 2,
  chaos_level = 1,
  tone_tags = array['Romantic', 'Poetic'],
  preview_quotes = array['Speak from the heart.', 'More feeling, less logic.', 'Romance me with your words.'],
  primary_color_hex = '6B4C7A'
where persona_id = 'poetic_romantic';

update public.judges set
  tagline = 'Convince me… if you dare.',
  difficulty_level = 4,
  chaos_level = 5,
  tone_tags = array['Chaotic'],
  preview_quotes = array['Beg harder.', 'That was cute.', 'You think that''ll work?'],
  primary_color_hex = '7CB342'
where persona_id = 'chaos_gremlin';

update public.judges set
  tagline = 'I''ve heard it all before.',
  difficulty_level = 3,
  chaos_level = 3,
  tone_tags = array['Strict'],
  preview_quotes = array['Prove it.', 'Actions speak louder.', 'Don''t waste my time.'],
  primary_color_hex = '8B0000'
where persona_id = 'the_ex';

update public.judges set
  tagline = 'Science meets romance.',
  difficulty_level = 2,
  chaos_level = 2,
  tone_tags = array['Analytical', 'Romantic'],
  preview_quotes = array['Data doesn''t lie.', 'Show me the chemistry.', 'Logical love wins.'],
  primary_color_hex = 'D4A574'
where persona_id = 'dr_love';

comment on column public.judges.season_start is 'NULL = permanent judge; set with season_end = seasonal, hidden when now() not between';
comment on column public.judges.is_premium is 'Premium (Wink+) only when true';
