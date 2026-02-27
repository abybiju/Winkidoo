-- "New" badge for seasonal judges: show when is_new and within 7 days of season start/created_at; client hides after 7 days.
alter table public.judges add column if not exists is_new boolean not null default true;

-- Existing judges are not "new"
update public.judges set is_new = false;

comment on column public.judges.is_new is 'Show "New" badge when true and within 7 days of season start/created_at; client hides after 7 days.';
