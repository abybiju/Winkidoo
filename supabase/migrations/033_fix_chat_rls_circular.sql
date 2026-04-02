-- 033: Fix Character Chat RLS circular reference
-- Problem: rooms SELECT → members table → co-members policy → rooms table → infinite loop
-- Fix: co-members policy references only character_chat_members (no rooms table)
--       rooms policy adds OR for created_by so creators always see their rooms

-- ── Fix character_chat_members co-members policy ──
-- Drop the circular policy
drop policy if exists "Users can read co-members" on public.character_chat_members;

-- Replace: user can see members of any room they themselves belong to
-- This only queries character_chat_members (same table), no cross-table cycle
create policy "Users can read co-members"
  on public.character_chat_members for select using (
    room_id in (
      select m.room_id from character_chat_members m where m.user_id = auth.uid()
    )
  );

-- ── Fix character_chat_rooms SELECT policy ──
-- Drop the existing rooms policy
drop policy if exists "Room members can read rooms" on public.character_chat_rooms;

-- Replace: member can read rooms they belong to, OR creator can always see,
-- OR authenticated user can look up by invite_code (needed for joinRoomByCode)
-- The members subquery now only hits character_chat_members (no cycle back to rooms)
create policy "Room members can read rooms"
  on public.character_chat_rooms for select using (
    created_by = auth.uid() or
    id in (select room_id from character_chat_members where user_id = auth.uid())
  );

-- ── RPC for joining room by invite code ──
-- Bypasses RLS (SECURITY DEFINER) so non-members can look up rooms by invite code
create or replace function public.join_chat_room_by_code(p_invite_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room_id uuid;
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select id into v_room_id
    from character_chat_rooms
    where invite_code = p_invite_code;

  if v_room_id is null then
    return null;
  end if;

  -- Insert membership if not already a member
  insert into character_chat_members (room_id, user_id, role)
    values (v_room_id, v_user_id, 'member')
    on conflict (room_id, user_id) do nothing;

  return v_room_id;
end;
$$;

-- ── Fix delete policy on members (same circular issue) ──
drop policy if exists "Users can leave or admin can remove" on public.character_chat_members;

create policy "Users can leave or admin can remove"
  on public.character_chat_members for delete using (
    user_id = auth.uid() or
    exists (
      select 1 from character_chat_members m
      where m.room_id = character_chat_members.room_id
      and m.user_id = auth.uid()
      and m.role = 'admin'
    )
  );
