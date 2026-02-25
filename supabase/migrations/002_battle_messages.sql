-- Live 3-way judge battle: chat messages per surprise
create table if not exists public.battle_messages (
  id uuid primary key default gen_random_uuid(),
  surprise_id uuid not null references public.surprises(id) on delete cascade,
  sender_type text not null check (sender_type in ('seeker', 'creator', 'judge')),
  sender_id uuid references auth.users(id) on delete set null,
  content text not null,
  is_verdict boolean not null default false,
  verdict_score int check (verdict_score is null or (verdict_score >= 0 and verdict_score <= 100)),
  verdict_unlocked boolean,
  created_at timestamptz not null default now()
);

create index if not exists idx_battle_messages_surprise_id on public.battle_messages(surprise_id);
create index if not exists idx_battle_messages_created_at on public.battle_messages(surprise_id, created_at);

alter table public.battle_messages enable row level security;

-- Couple members can read messages for their surprise (drop first so re-run is safe)
drop policy if exists "Couple can read battle_messages" on public.battle_messages;
drop policy if exists "Couple member can insert battle_message" on public.battle_messages;
create policy "Couple can read battle_messages"
  on public.battle_messages for select
  using (
    exists (
      select 1 from public.surprises s
      join public.couples c on c.id = s.couple_id
      where s.id = surprise_id and (c.user_a_id = auth.uid() or c.user_b_id = auth.uid())
    )
  );

-- Seeker and creator can insert (judge rows inserted by app with service role or same client after AI call)
create policy "Couple member can insert battle_message"
  on public.battle_messages for insert
  with check (
    exists (
      select 1 from public.surprises s
      join public.couples c on c.id = s.couple_id
      where s.id = surprise_id and (c.user_a_id = auth.uid() or c.user_b_id = auth.uid())
    )
  );

-- Enable Realtime for battle_messages (only if not already in publication, so re-run is safe)
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'battle_messages'
  ) then
    alter publication supabase_realtime add table public.battle_messages;
  end if;
end
$$;
