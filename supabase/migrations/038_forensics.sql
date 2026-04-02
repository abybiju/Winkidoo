-- 038: Emotional Forensics — post-battle communication analysis
-- Stores AI-generated communication DNA reports per battle.

create table public.forensics_reports (
  id                uuid primary key default gen_random_uuid(),
  surprise_id       uuid not null references surprises(id) on delete cascade,
  couple_id         uuid not null references couples(id) on delete cascade,
  communication_dna jsonb not null default '{}',
  hidden_signals    jsonb not null default '[]',
  growth_edge       text,
  superpower        text,
  report_json       jsonb not null default '{}',
  created_at        timestamptz default now()
);

create index idx_forensics_couple on forensics_reports(couple_id);
create index idx_forensics_surprise on forensics_reports(surprise_id);

alter table public.forensics_reports enable row level security;

-- Couple members can read their own reports
create policy "Couple members can read forensics"
  on public.forensics_reports for select using (
    couple_id in (
      select id from couples
      where user_a_id = auth.uid() or user_b_id = auth.uid()
    )
  );

create policy "Authenticated users can insert forensics"
  on public.forensics_reports for insert
  with check (auth.role() = 'authenticated');
