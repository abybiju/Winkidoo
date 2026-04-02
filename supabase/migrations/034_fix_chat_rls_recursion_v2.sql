-- 034: Fix remaining RLS recursion on character_chat_members
-- Problem: "co-members" policy queries character_chat_members from within
--          a policy ON character_chat_members → PostgreSQL detects infinite recursion.
-- Same issue on the delete policy (self-referential admin check).
--
-- Fix: Remove ALL self-referential policies. Keep only the simple
--      "user_id = auth.uid()" policy. Use SECURITY DEFINER RPCs for
--      operations that need to see other members' rows.

-- ── 1. Drop the recursive SELECT policy ──
drop policy if exists "Users can read co-members" on public.character_chat_members;
-- "Users can read own memberships" (user_id = auth.uid()) remains — no recursion.

-- ── 2. Drop the recursive DELETE policy ──
drop policy if exists "Users can leave or admin can remove" on public.character_chat_members;

-- Simple non-recursive delete: user can only remove their own row (leave)
create policy "Users can leave rooms"
  on public.character_chat_members for delete using (
    user_id = auth.uid()
  );

-- ── 3. RPC to fetch all members of a room (bypasses RLS) ──
-- Caller must be a member of the room; returns all members.
create or replace function public.get_chat_room_members(p_room_id uuid)
returns setof character_chat_members
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Verify caller is a member
  if not exists (
    select 1 from character_chat_members
    where room_id = p_room_id and user_id = auth.uid()
  ) then
    raise exception 'Not a member of this room';
  end if;

  return query
    select * from character_chat_members
    where room_id = p_room_id
    order by joined_at;
end;
$$;

-- ── 4. RPC for admin to remove a member (bypasses RLS) ──
create or replace function public.remove_chat_room_member(
  p_room_id uuid,
  p_target_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Verify caller is an admin of this room
  if not exists (
    select 1 from character_chat_members
    where room_id = p_room_id and user_id = auth.uid() and role = 'admin'
  ) then
    raise exception 'Only room admins can remove members';
  end if;

  delete from character_chat_members
  where room_id = p_room_id and user_id = p_target_user_id;
end;
$$;
