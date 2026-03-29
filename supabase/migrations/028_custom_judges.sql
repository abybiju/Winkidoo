-- 028: Custom AI Judge Creator + Community Marketplace
-- Users create judges based on any famous personality. AI generates persona
-- prompts based on the personality + mood. Community marketplace for sharing.

-- ── Custom judges ──
create table public.custom_judges (
  id                      uuid primary key default gen_random_uuid(),
  couple_id               uuid not null references public.couples(id) on delete cascade,
  personality_name        text not null,
  personality_query       text not null,
  mood                    text not null default 'funny',
  generated_persona_prompt text not null,
  generated_how_to_impress text,
  preview_quotes          text[] default '{}',
  avatar_storage_path     text,
  avatar_emoji            text default '🎭',
  difficulty_level        int not null default 2 check (difficulty_level between 1 and 5),
  chaos_level             int not null default 2 check (chaos_level between 1 and 5),
  is_published            boolean default false,
  use_count               int default 0,
  is_flagged              boolean default false,
  created_at              timestamptz default now()
);

-- ── Marketplace usage tracking ──
create table public.custom_judge_uses (
  id                uuid primary key default gen_random_uuid(),
  custom_judge_id   uuid not null references custom_judges(id) on delete cascade,
  couple_id         uuid not null references couples(id) on delete cascade,
  used_at           timestamptz default now(),
  constraint unique_judge_use unique (custom_judge_id, couple_id)
);

-- ── Add custom_judge_id to existing tables (backward compatible) ──
alter table public.surprises add column if not exists custom_judge_id uuid references custom_judges(id) on delete set null;
alter table public.daily_dares add column if not exists custom_judge_id uuid references custom_judges(id) on delete set null;
alter table public.daily_mini_games add column if not exists custom_judge_id uuid references custom_judges(id) on delete set null;

-- ── Indexes ──
create index idx_custom_judges_couple on custom_judges(couple_id);
create index idx_custom_judges_published on custom_judges(is_published, is_flagged) where is_published = true and is_flagged = false;
create index idx_custom_judges_trending on custom_judges(use_count desc) where is_published = true and is_flagged = false;
create index idx_custom_judge_uses_couple on custom_judge_uses(couple_id);
create index idx_custom_judge_uses_judge on custom_judge_uses(custom_judge_id);

-- ── RLS ──
alter table public.custom_judges enable row level security;
alter table public.custom_judge_uses enable row level security;

-- Creator can manage their own custom judges
create policy "Users can read their own custom judges"
  on public.custom_judges for select using (
    couple_id in (select id from couples where user_a_id = auth.uid() or user_b_id = auth.uid())
  );

-- All authenticated users can read published judges (marketplace)
create policy "Authenticated users can read published judges"
  on public.custom_judges for select using (
    is_published = true and is_flagged = false
  );

create policy "Users can create custom judges"
  on public.custom_judges for insert with check (
    couple_id in (select id from couples where user_a_id = auth.uid() or user_b_id = auth.uid())
  );

create policy "Users can update their own custom judges"
  on public.custom_judges for update using (
    couple_id in (select id from couples where user_a_id = auth.uid() or user_b_id = auth.uid())
  );

create policy "Users can delete their own custom judges"
  on public.custom_judges for delete using (
    couple_id in (select id from couples where user_a_id = auth.uid() or user_b_id = auth.uid())
  );

-- Custom judge uses
create policy "Users can read their judge uses"
  on public.custom_judge_uses for select using (
    couple_id in (select id from couples where user_a_id = auth.uid() or user_b_id = auth.uid())
  );

create policy "Users can add judge uses"
  on public.custom_judge_uses for insert with check (
    couple_id in (select id from couples where user_a_id = auth.uid() or user_b_id = auth.uid())
  );
