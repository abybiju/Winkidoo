-- 037: Phantom Judge Takeover
-- Tracks phantom judge events during battles.

create table public.phantom_events (
  id              uuid primary key default gen_random_uuid(),
  surprise_id     uuid not null references surprises(id) on delete cascade,
  phantom_persona text not null,
  triggered_at    timestamptz default now(),
  exchanges_count int not null default 0,
  resistance_delta int not null default 0
);

create index idx_phantom_events_surprise on phantom_events(surprise_id);

alter table public.phantom_events enable row level security;

-- Anyone who can see the surprise can see phantom events
create policy "Couple members can read phantom events"
  on public.phantom_events for select using (
    surprise_id in (
      select id from surprises where couple_id in (
        select couple_id from couples
        where user_a_id = auth.uid() or user_b_id = auth.uid()
      )
    )
  );

create policy "System can insert phantom events"
  on public.phantom_events for insert
  with check (auth.role() = 'authenticated');

-- Add had_phantom flag to surprises
alter table public.surprises
  add column if not exists had_phantom boolean not null default false;
