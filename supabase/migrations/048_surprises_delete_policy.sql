-- 048_surprises_delete_policy.sql
-- Allow a surprise's CREATOR to delete it at any time.
--
-- The surprises table (migration 001) shipped with SELECT/INSERT/UPDATE RLS
-- policies but NO delete policy, so DELETE was blocked for everyone. The
-- creator now gets a "delete surprise" action in the vault (with a warning),
-- so add a DELETE policy scoped to the creator.
--
-- battle_messages cascade-delete via their FK to surprises (migration 002).
-- Storage objects (photo/voice) are removed client-side before the row delete.

drop policy if exists "Creator can delete surprise" on public.surprises;

create policy "Creator can delete surprise"
  on public.surprises for delete
  using (creator_id = auth.uid());
