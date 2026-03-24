-- ============================================================
-- Migration 015: Daily activity log for daily streaks
-- ============================================================

-- Lightweight table: one row per active day per user.
-- Any vault activity counts (surprise created, battle message sent, battle resolved).
create table if not exists public.daily_activity_log (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  couple_id     uuid not null references public.couples(id) on delete cascade,
  activity_date date not null default current_date,
  activity_type text not null check (activity_type in ('surprise_created', 'message_sent', 'battle_resolved', 'quest_step')),
  created_at    timestamptz not null default now(),
  -- One entry per user per day per type is enough
  constraint daily_activity_unique unique (user_id, activity_date, activity_type)
);

-- RLS: users can only see/insert their own activity
alter table public.daily_activity_log enable row level security;

create policy "Users can view own activity"
  on public.daily_activity_log for select
  using (user_id = auth.uid());

create policy "Users can insert own activity"
  on public.daily_activity_log for insert
  with check (user_id = auth.uid());

-- Fast lookups for streak calculation
create index if not exists idx_daily_activity_user_date
  on public.daily_activity_log(user_id, activity_date desc);

create index if not exists idx_daily_activity_couple_date
  on public.daily_activity_log(couple_id, activity_date desc);

-- Streak freeze tracking (purchased with Winks)
create table if not exists public.streak_freezes (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  couple_id   uuid not null references public.couples(id) on delete cascade,
  freeze_date date not null,
  created_at  timestamptz not null default now(),
  constraint streak_freeze_unique unique (couple_id, freeze_date)
);

alter table public.streak_freezes enable row level security;

create policy "Couple members can view streak freezes"
  on public.streak_freezes for select
  using (
    couple_id in (
      select c.id from public.couples c
      where c.user_a_id = auth.uid() or c.user_b_id = auth.uid()
    )
  );

create policy "Users can insert streak freezes"
  on public.streak_freezes for insert
  with check (user_id = auth.uid());
