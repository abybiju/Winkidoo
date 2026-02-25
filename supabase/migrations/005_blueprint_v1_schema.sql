-- Blueprint v1: surprise battle status/archive, battle state on surprise, treasure archive, judges
-- Requires: 001_initial_schema, 002_battle_messages, 003_wink_plus, 004_surprise_type_photo (run in order)

-- Surprises: battle status, archived flag, and battle state (Option A: columns on surprises)
alter table public.surprises
  add column if not exists battle_status text not null default 'active'
  check (battle_status in ('active', 'resolved'));

alter table public.surprises
  add column if not exists archived_flag boolean not null default false;

alter table public.surprises
  add column if not exists seeker_score int not null default 0;

alter table public.surprises
  add column if not exists resistance_score int;

alter table public.surprises
  add column if not exists fatigue_level int not null default 0;

alter table public.surprises
  add column if not exists last_activity_at timestamptz;

alter table public.surprises
  add column if not exists winner text;

alter table public.surprises
  add column if not exists creator_defense_count int not null default 0;

comment on column public.surprises.battle_status is 'active = battle in progress; resolved = ended (unlocked or denied)';
comment on column public.surprises.archived_flag is 'true when user chose Keep in Treasure';
comment on column public.surprises.seeker_score is 'Running persuasion score for DRS comparison';
comment on column public.surprises.resistance_score is 'Dynamic resistance score (base + chaos + creator - fatigue)';
comment on column public.surprises.creator_defense_count is 'Number of creator defense messages (diminishing reinforcement)';

-- Treasure archive: metadata for kept battles (Wink+ can reopen content later)
create table if not exists public.treasure_archive (
  id uuid primary key default gen_random_uuid(),
  surprise_id uuid not null references public.surprises(id) on delete cascade,
  couple_id uuid not null references public.couples(id) on delete cascade,
  judge_persona text not null,
  attempts_count int not null default 0,
  creator_interventions_count int not null default 0,
  winner text,
  final_quote text,
  archived_at timestamptz not null default now(),
  content_reopen_allowed boolean not null default true
);

create index if not exists idx_treasure_archive_couple_id on public.treasure_archive(couple_id);
create index if not exists idx_treasure_archive_archived_at on public.treasure_archive(archived_at desc);

alter table public.treasure_archive enable row level security;

create policy "Couple can read own treasure_archive"
  on public.treasure_archive for select
  using (
    exists (
      select 1 from public.couples c
      where c.id = couple_id and (c.user_a_id = auth.uid() or c.user_b_id = auth.uid())
    )
  );

create policy "Couple member can insert treasure_archive"
  on public.treasure_archive for insert
  with check (
    exists (
      select 1 from public.couples c
      where c.id = couple_id and (c.user_a_id = auth.uid() or c.user_b_id = auth.uid())
    )
  );

-- Judges: optional metadata for avatar, accent, seasonal (app still uses persona IDs)
create table if not exists public.judges (
  id uuid primary key default gen_random_uuid(),
  persona_id text not null unique check (persona_id in (
    'sassy_cupid', 'poetic_romantic', 'chaos_gremlin', 'the_ex', 'dr_love'
  )),
  name text not null,
  accent_color_hex text,
  avatar_asset_path text,
  unlock_animation_type text,
  season_start date,
  season_end date,
  premium_flag boolean not null default false
);

alter table public.judges enable row level security;

create policy "Anyone can read judges"
  on public.judges for select
  using (true);

-- Seed core judges (no avatar paths yet; app uses persona IDs, can look up accent later)
insert into public.judges (persona_id, name, accent_color_hex, premium_flag)
values
  ('sassy_cupid', 'Sassy Cupid', 'FF6B9D', false),
  ('poetic_romantic', 'Poetic Romantic', 'C44569', false),
  ('chaos_gremlin', 'Chaos Gremlin', 'F8B500', true),
  ('the_ex', 'The Ex', '8B5A6B', true),
  ('dr_love', 'Dr. Love', '6B9D7A', true)
on conflict (persona_id) do nothing;
