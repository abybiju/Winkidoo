-- Enable Realtime for surprises (battle row updates: battle_status, resolved_at, etc.)
-- Only if not already in publication, so re-run is safe.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'surprises'
  ) then
    alter publication supabase_realtime add table public.surprises;
  end if;
end
$$;
