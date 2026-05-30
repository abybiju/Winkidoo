-- Migration 046: RLS policies for the `surprises` storage bucket
--
-- BUG: Photo/voice surprise uploads failed with
--   StorageException(message: new row violates row-level security policy,
--   statusCode: 403, error: Unauthorized)
-- because the `surprises` bucket had RLS enabled on storage.objects but ZERO
-- policies permitting access. (Only judge-avatars / profile-avatars had policies;
-- the surprises bucket policies were never captured in a migration.)
--
-- Surprise media is stored at path:  <couple_id>/<uuid>.<ext>
-- (see lib/features/vault/create_surprise_screen.dart and dare_response_sheet.dart)
-- so we scope access to members of the couple named by the first path segment.

insert into storage.buckets (id, name, public)
values ('surprises', 'surprises', false)
on conflict (id) do nothing;

-- INSERT: a couple member may upload media under their own couple's folder.
drop policy if exists "Couple member write surprise media" on storage.objects;
create policy "Couple member write surprise media"
  on storage.objects for insert
  with check (
    bucket_id = 'surprises'
    and exists (
      select 1 from public.couples c
      where c.id::text = (storage.foldername(name))[1]
        and (c.user_a_id = auth.uid() or c.user_b_id = auth.uid())
    )
  );

-- SELECT: a couple member may read media under their own couple's folder.
drop policy if exists "Couple member read surprise media" on storage.objects;
create policy "Couple member read surprise media"
  on storage.objects for select
  using (
    bucket_id = 'surprises'
    and exists (
      select 1 from public.couples c
      where c.id::text = (storage.foldername(name))[1]
        and (c.user_a_id = auth.uid() or c.user_b_id = auth.uid())
    )
  );

-- UPDATE: needed if media is ever re-uploaded (upsert) to the same path.
drop policy if exists "Couple member update surprise media" on storage.objects;
create policy "Couple member update surprise media"
  on storage.objects for update
  using (
    bucket_id = 'surprises'
    and exists (
      select 1 from public.couples c
      where c.id::text = (storage.foldername(name))[1]
        and (c.user_a_id = auth.uid() or c.user_b_id = auth.uid())
    )
  )
  with check (
    bucket_id = 'surprises'
    and exists (
      select 1 from public.couples c
      where c.id::text = (storage.foldername(name))[1]
        and (c.user_a_id = auth.uid() or c.user_b_id = auth.uid())
    )
  );

-- DELETE: powers auto-delete / "after viewing" cleanup of surprise media.
drop policy if exists "Couple member delete surprise media" on storage.objects;
create policy "Couple member delete surprise media"
  on storage.objects for delete
  using (
    bucket_id = 'surprises'
    and exists (
      select 1 from public.couples c
      where c.id::text = (storage.foldername(name))[1]
        and (c.user_a_id = auth.uid() or c.user_b_id = auth.uid())
    )
  );
