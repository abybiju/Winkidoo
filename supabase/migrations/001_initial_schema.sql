-- Winkidoo initial schema
-- Run in Supabase SQL Editor or via supabase db push

-- Couples: one row per couple, user_a creates, user_b joins with invite code
create table if not exists public.couples (
  id uuid primary key default gen_random_uuid(),
  user_a_id uuid not null references auth.users(id) on delete cascade,
  user_b_id uuid references auth.users(id) on delete set null,
  invite_code text not null unique,
  linked_at timestamptz,
  created_at timestamptz not null default now()
);

-- Surprises: hidden content (encrypted), judge config, unlock state
create table if not exists public.surprises (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  creator_id uuid not null references auth.users(id) on delete cascade,
  content_encrypted text not null,
  unlock_method text not null check (unlock_method in ('persuade', 'collaborate')),
  judge_persona text not null check (judge_persona in (
    'sassy_cupid', 'poetic_romantic', 'chaos_gremlin', 'the_ex', 'dr_love'
  )),
  difficulty_level int not null check (difficulty_level between 1 and 5) default 2,
  auto_delete_at timestamptz,
  is_unlocked boolean not null default false,
  unlocked_at timestamptz,
  created_at timestamptz not null default now()
);

-- Attempts: each submission to the judge
create table if not exists public.attempts (
  id uuid primary key default gen_random_uuid(),
  surprise_id uuid not null references public.surprises(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  ai_score int,
  ai_commentary text,
  created_at timestamptz not null default now()
);

-- Winks balance per user
create table if not exists public.winks_balance (
  user_id uuid primary key references auth.users(id) on delete cascade,
  balance int not null default 0 check (balance >= 0),
  last_updated timestamptz not null default now()
);

-- Transactions log for Winks
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount int not null,
  type text not null,
  description text,
  created_at timestamptz not null default now()
);

-- RLS
alter table public.couples enable row level security;
alter table public.surprises enable row level security;
alter table public.attempts enable row level security;
alter table public.winks_balance enable row level security;
alter table public.transactions enable row level security;

-- Couples: users can read/insert/update only their own couple (drop first so re-run is safe)
drop policy if exists "Users can read own couple" on public.couples;
drop policy if exists "Users can insert couple as user_a" on public.couples;
drop policy if exists "Users can update couple for link" on public.couples;
create policy "Users can read own couple"
  on public.couples for select
  using (
    auth.uid() = user_a_id or auth.uid() = user_b_id
  );
create policy "Users can insert couple as user_a"
  on public.couples for insert
  with check (auth.uid() = user_a_id);
create policy "Users can update couple for link"
  on public.couples for update
  using (auth.uid() = user_a_id or auth.uid() = user_b_id);

-- Surprises: couple members only
drop policy if exists "Couple can read surprises" on public.surprises;
drop policy if exists "Couple member can insert surprise" on public.surprises;
drop policy if exists "Couple can update surprise" on public.surprises;
create policy "Couple can read surprises"
  on public.surprises for select
  using (
    exists (
      select 1 from public.couples c
      where c.id = couple_id and (c.user_a_id = auth.uid() or c.user_b_id = auth.uid())
    )
  );
create policy "Couple member can insert surprise"
  on public.surprises for insert
  with check (
    exists (
      select 1 from public.couples c
      where c.id = couple_id and (c.user_a_id = auth.uid() or c.user_b_id = auth.uid())
    )
  );
create policy "Couple can update surprise"
  on public.surprises for update
  using (
    exists (
      select 1 from public.couples c
      where c.id = couple_id and (c.user_a_id = auth.uid() or c.user_b_id = auth.uid())
    )
  );

-- Attempts: couple members only
drop policy if exists "Couple can read attempts" on public.attempts;
drop policy if exists "Couple member can insert attempt" on public.attempts;
create policy "Couple can read attempts"
  on public.attempts for select
  using (
    exists (
      select 1 from public.surprises s
      join public.couples c on c.id = s.couple_id
      where s.id = surprise_id and (c.user_a_id = auth.uid() or c.user_b_id = auth.uid())
    )
  );
create policy "Couple member can insert attempt"
  on public.attempts for insert
  with check (auth.uid() = user_id);

-- Winks: own row only
drop policy if exists "User can read own winks" on public.winks_balance;
drop policy if exists "User can insert own winks" on public.winks_balance;
drop policy if exists "User can update own winks" on public.winks_balance;
create policy "User can read own winks"
  on public.winks_balance for select
  using (auth.uid() = user_id);
create policy "User can insert own winks"
  on public.winks_balance for insert
  with check (auth.uid() = user_id);
create policy "User can update own winks"
  on public.winks_balance for update
  using (auth.uid() = user_id);

-- Transactions: own only
drop policy if exists "User can read own transactions" on public.transactions;
drop policy if exists "User can insert own transaction" on public.transactions;
create policy "User can read own transactions"
  on public.transactions for select
  using (auth.uid() = user_id);
create policy "User can insert own transaction"
  on public.transactions for insert
  with check (auth.uid() = user_id);

-- Realtime for surprises (optional: enable in Supabase dashboard for surprises table)
-- alter publication supabase_realtime add table public.surprises;

-- Seed new users with initial Winks (e.g. 10 free). Use trigger or app logic.
-- Here we rely on app to create winks_balance row on first use or signup.
create or replace function public.ensure_winks_balance()
returns trigger as $$
begin
  insert into public.winks_balance (user_id, balance, last_updated)
  values (new.id, 10, now())
  on conflict (user_id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

-- Trigger on auth.users: create winks_balance when user signs up (run in Supabase SQL)
-- This requires trigger on auth.users which may need Supabase dashboard. Alternatively handle in app.
-- So we skip trigger and create row in app when user first opens app or links.
