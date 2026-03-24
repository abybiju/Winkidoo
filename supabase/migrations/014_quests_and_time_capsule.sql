-- ============================================================
-- Migration 014: Love Quests + Time Capsule support
-- ============================================================

-- 1. Quests table: co-op surprise chains
create table if not exists public.quests (
  id          uuid primary key default gen_random_uuid(),
  couple_id   uuid not null references public.couples(id) on delete cascade,
  creator_id  uuid not null references auth.users(id),
  title       text not null,
  description text,
  total_steps int not null default 3 check (total_steps between 3 and 7),
  current_step int not null default 0,
  status      text not null default 'active' check (status in ('active', 'completed', 'abandoned')),
  judge_persona text not null default 'sassy_cupid',
  difficulty_start int not null default 1 check (difficulty_start between 1 and 5),
  difficulty_end   int not null default 3 check (difficulty_end between 1 and 5),
  created_at  timestamptz not null default now(),
  completed_at timestamptz,
  constraint quests_difficulty_escalation check (difficulty_end >= difficulty_start)
);

-- RLS: only couple members can access their quests
alter table public.quests enable row level security;

create policy "Couple members can view their quests"
  on public.quests for select
  using (
    couple_id in (
      select c.id from public.couples c
      where c.user_a_id = auth.uid() or c.user_b_id = auth.uid()
    )
  );

create policy "Couple members can insert quests"
  on public.quests for insert
  with check (
    couple_id in (
      select c.id from public.couples c
      where c.user_a_id = auth.uid() or c.user_b_id = auth.uid()
    )
    and creator_id = auth.uid()
  );

create policy "Couple members can update their quests"
  on public.quests for update
  using (
    couple_id in (
      select c.id from public.couples c
      where c.user_a_id = auth.uid() or c.user_b_id = auth.uid()
    )
  );

-- Index for fast lookup by couple
create index if not exists idx_quests_couple_id on public.quests(couple_id);

-- 2. Add quest link + time capsule columns to surprises
alter table public.surprises
  add column if not exists quest_id uuid references public.quests(id) on delete set null,
  add column if not exists quest_step int,
  add column if not exists unlock_after timestamptz;

-- Index for fetching surprises by quest
create index if not exists idx_surprises_quest_id on public.surprises(quest_id);

-- 3. Quest rewards table: collectibles earned by completing quests
create table if not exists public.quest_rewards (
  id          uuid primary key default gen_random_uuid(),
  quest_id    uuid not null references public.quests(id) on delete cascade,
  couple_id   uuid not null references public.couples(id) on delete cascade,
  reward_type text not null default 'badge' check (reward_type in ('badge', 'winks', 'judge_skin')),
  reward_data jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

alter table public.quest_rewards enable row level security;

create policy "Couple members can view their quest rewards"
  on public.quest_rewards for select
  using (
    couple_id in (
      select c.id from public.couples c
      where c.user_a_id = auth.uid() or c.user_b_id = auth.uid()
    )
  );

create policy "System can insert quest rewards"
  on public.quest_rewards for insert
  with check (
    couple_id in (
      select c.id from public.couples c
      where c.user_a_id = auth.uid() or c.user_b_id = auth.uid()
    )
  );

-- 4. Enable realtime on quests for live progress updates
alter publication supabase_realtime add table public.quests;
