-- One-time "New Judge Has Arrived" push when seasonal judge becomes active; set true after send to prevent duplicates.
alter table public.judges add column if not exists season_push_sent boolean not null default false;

comment on column public.judges.season_push_sent is 'Set true after sending season-launch push; prevents duplicate announcements.';
