-- Migration 031: Create dedicated storage bucket for custom judge avatars
-- The 'surprises' bucket RLS blocks custom_judges/ paths, so we need a separate bucket.

insert into storage.buckets (id, name, public)
values ('judge-avatars', 'judge-avatars', false)
on conflict (id) do nothing;

-- Authenticated users can read any judge avatar (needed for marketplace)
create policy "Authenticated read judge avatars"
  on storage.objects for select
  using (bucket_id = 'judge-avatars' and auth.role() = 'authenticated');

-- Users can upload judge avatars under their own user ID folder
create policy "Users write own judge avatars"
  on storage.objects for insert
  with check (
    bucket_id = 'judge-avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Users can update (upsert) their own judge avatars
create policy "Users update own judge avatars"
  on storage.objects for update
  using (
    bucket_id = 'judge-avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'judge-avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Users can delete their own judge avatars
create policy "Users delete own judge avatars"
  on storage.objects for delete
  using (
    bucket_id = 'judge-avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
