-- 056_chat_member_names_and_approval.sql
-- Two chat-group fixes:
--  (A) Sender NAMES never showed in chat — get_chat_room_members returned only the
--      raw character_chat_members columns (no display_name/email), so the UI had
--      nothing to render. Enrich it with profiles.display_name + auth email.
--  (B) Anyone with the invite code joined a group instantly. Add a membership
--      `status` ('active' | 'pending'): friends added at room creation are 'active';
--      invite-code joiners land 'pending' and a room admin must approve them.
--      Pending members cannot read or send messages until approved.

-- ── 1. Membership status. Default 'active' so all EXISTING members stay in. ──
alter table public.character_chat_members
  add column if not exists status text not null default 'active'
    check (status in ('active', 'pending'));

create index if not exists idx_chat_members_room_status
  on public.character_chat_members (room_id, status);

-- ── 2. Join-by-code now creates a PENDING membership (was instant member). ──
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

  -- Pending: the room admin must approve. (do nothing if already a member of any status)
  insert into character_chat_members (room_id, user_id, role, status)
    values (v_room_id, v_user_id, 'member', 'pending')
    on conflict (room_id, user_id) do nothing;

  return v_room_id;
end;
$$;

-- ── 3. Admin approves a pending member. ──
create or replace function public.approve_chat_room_member(
  p_room_id uuid,
  p_target_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from character_chat_members
    where room_id = p_room_id and user_id = auth.uid()
      and role = 'admin' and status = 'active'
  ) then
    raise exception 'Only room admins can approve members';
  end if;

  update character_chat_members
    set status = 'active'
    where room_id = p_room_id and user_id = p_target_user_id;
end;
$$;

-- ── 4. Enriched members RPC: returns status + real display_name + email. ──
--    Caller must be an ACTIVE member (pending users see only a waiting screen,
--    driven by their own membership row, not the full roster).
drop function if exists public.get_chat_room_members(uuid);
create or replace function public.get_chat_room_members(p_room_id uuid)
returns table (
  id uuid,
  room_id uuid,
  user_id uuid,
  role text,
  status text,
  joined_at timestamptz,
  display_name text,
  email text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from character_chat_members
    where room_id = p_room_id and user_id = auth.uid() and status = 'active'
  ) then
    raise exception 'Not an active member of this room';
  end if;

  return query
    select m.id, m.room_id, m.user_id, m.role, m.status, m.joined_at,
           p.display_name,
           u.email::text
    from character_chat_members m
    left join public.profiles p on p.user_id = m.user_id
    left join auth.users u on u.id = m.user_id
    where m.room_id = p_room_id
    order by m.status desc, m.joined_at;  -- pending first for admin visibility
end;
$$;

-- ── 5. Messages: only ACTIVE members may read/insert (gate pending users out). ──
drop policy if exists "Room members can read messages" on public.character_chat_messages;
create policy "Room members can read messages"
  on public.character_chat_messages for select using (
    room_id in (
      select room_id from character_chat_members
      where user_id = auth.uid() and status = 'active'
    )
  );

drop policy if exists "Room members can insert messages" on public.character_chat_messages;
create policy "Room members can insert messages"
  on public.character_chat_messages for insert with check (
    sender_id = auth.uid() and room_id in (
      select room_id from character_chat_members
      where user_id = auth.uid() and status = 'active'
    )
  );

-- ── 6. In-app notifications for the approval flow: ──
--    * pending join request  -> notify the room creator/admin
--    * approved              -> notify the joiner
create or replace function public.notify_chat_member_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_room record;
  v_actor_name text;
begin
  select id, name, created_by into v_room
    from public.character_chat_rooms where id = new.room_id;
  if v_room.id is null then return new; end if;

  if (tg_op = 'INSERT' and new.status = 'pending') then
    select coalesce(nullif(trim(display_name), ''), 'Someone')
      into v_actor_name from public.profiles where user_id = new.user_id;
    insert into public.notifications (user_id, type, title, body, data)
    values (
      v_room.created_by,
      'chat_join_request',
      'New join request',
      coalesce(v_actor_name, 'Someone') || ' wants to join '
        || coalesce(nullif(v_room.name, ''), 'your group'),
      jsonb_build_object('type', 'chat_join_request', 'room_id', new.room_id,
                         'from_user_id', new.user_id)
    );
  elsif (tg_op = 'UPDATE' and new.status = 'active'
         and old.status = 'pending') then
    insert into public.notifications (user_id, type, title, body, data)
    values (
      new.user_id,
      'chat_join_approved',
      'You''re in!',
      'You were approved to join '
        || coalesce(nullif(v_room.name, ''), 'the group'),
      jsonb_build_object('type', 'chat_join_approved', 'room_id', new.room_id)
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_notify_chat_join_request on public.character_chat_members;
create trigger trg_notify_chat_join_request
  after insert on public.character_chat_members
  for each row execute function public.notify_chat_member_event();

drop trigger if exists trg_notify_chat_join_approved on public.character_chat_members;
create trigger trg_notify_chat_join_approved
  after update of status on public.character_chat_members
  for each row execute function public.notify_chat_member_event();

-- ── 7. create_chat_room RPC. ──
-- The members INSERT policy only allows auth.uid() = user_id, so the client
-- could never add OTHER users to a room (group creation with friends silently
-- failed RLS). This SECURITY DEFINER RPC creates the room, adds the caller as
-- admin, and adds each selected member AS AN ACTIVE MEMBER — but only if they
-- are an accepted friend of the caller (enforces "only friends added directly").
create or replace function public.create_chat_room(
  p_type text,
  p_name text,
  p_member_ids uuid[]
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_room_id uuid;
  v_mid uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.character_chat_rooms (type, name, created_by)
    values (coalesce(nullif(trim(p_type), ''), 'friend'),
            nullif(trim(coalesce(p_name, '')), ''),
            v_uid)
    returning id into v_room_id;

  insert into public.character_chat_members (room_id, user_id, role, status)
    values (v_room_id, v_uid, 'admin', 'active');

  if p_member_ids is not null then
    foreach v_mid in array p_member_ids loop
      if v_mid <> v_uid and exists (
        select 1 from public.user_friends uf
        where uf.status = 'accepted'
          and ((uf.user_a_id = v_uid and uf.user_b_id = v_mid)
            or (uf.user_a_id = v_mid and uf.user_b_id = v_uid))
      ) then
        insert into public.character_chat_members (room_id, user_id, role, status)
          values (v_room_id, v_mid, 'member', 'active')
          on conflict (room_id, user_id) do nothing;
      end if;
    end loop;
  end if;

  return v_room_id;
end;
$$;

grant execute on function public.create_chat_room(text, text, uuid[]) to authenticated;
