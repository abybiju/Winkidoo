-- Add resolved_at to surprises for explicit battle resolution time (persistent + pausable battles)
-- Requires: 001–005 (run in order)

alter table public.surprises
  add column if not exists resolved_at timestamptz;

comment on column public.surprises.resolved_at is 'When battle_status was set to resolved (null while active).';
