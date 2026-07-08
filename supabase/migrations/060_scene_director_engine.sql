-- Migration 060: Scene Party Director engine — counters, turn CAS, notifications
-- Run in Supabase Dashboard → SQL Editor (after 058/059)
--
-- Powers the scene-director Edge Function (Phase B): message counters decide
-- when the Director/castmates act; claim_director_turn guarantees N clients
-- ticking concurrently produce exactly ONE director action (single-statement
-- compare-and-swap + a 25s lease that self-heals a crashed turn).

-- ── 1. Message counters (maintained by trigger, read by the turn policy) ──

create or replace function public.scene_msg_counters()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.message_type = 'user' then
    update public.scene_sessions
       set user_msgs_in_act = user_msgs_in_act + 1,
           msgs_since_director = msgs_since_director + 1,
           msgs_since_castmate = msgs_since_castmate + 1
     where room_id = new.room_id and status = 'live';
  elsif new.message_type = 'director' then
    update public.scene_sessions
       set msgs_since_director = 0
     where room_id = new.room_id and status = 'live';
  elsif new.message_type = 'castmate' then
    update public.scene_sessions
       set msgs_since_castmate = 0,
           castmate_msgs_in_act = castmate_msgs_in_act + 1
     where room_id = new.room_id and status = 'live';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_scene_msg_counters on public.character_chat_messages;
create trigger trg_scene_msg_counters
  after insert on public.character_chat_messages
  for each row execute function public.scene_msg_counters();

-- ── 2. Director turn claim (CAS + lease) ──────────────────────────────────
-- Called ONLY by the scene-director Edge Function (service role). Returns the
-- new version on success, no rows when another tick already claimed the turn
-- or a lease is still active.

create or replace function public.claim_director_turn(
  p_session_id uuid,
  p_expected_version int
)
returns int
language sql
security definer
set search_path = public
as $$
  update public.scene_sessions
     set version = version + 1,
         director_busy_until = now() + interval '25 seconds'
   where id = p_session_id
     and version = p_expected_version
     and (director_busy_until is null or director_busy_until < now())
  returning version;
$$;

revoke execute on function public.claim_director_turn(uuid, int) from public;
revoke execute on function public.claim_director_turn(uuid, int) from anon;
revoke execute on function public.claim_director_turn(uuid, int) from authenticated;
grant execute on function public.claim_director_turn(uuid, int) to service_role;

-- ── 2b. Fix get_scene_cast (058 shipped with a bad profiles join) ─────────
-- profiles is keyed by user_id (not id) — 058's `p.id = c.user_id` fails at
-- runtime, so the casting screen saw an empty cast. Recreate with the right
-- join; signature unchanged.

create or replace function public.get_scene_cast(p_room_id uuid)
returns table (
  cast_id uuid,
  character_id uuid,
  character_slug text,
  character_name text,
  character_emoji text,
  character_color_hex text,
  character_tagline text,
  is_lead boolean,
  sort_order int,
  user_id uuid,
  is_ai boolean,
  display_name text,
  best_performance_count int,
  game_points int,
  secret_goal text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;
  if not exists (select 1 from public.character_chat_members m
                 where m.room_id = p_room_id and m.user_id = v_uid
                   and m.status = 'active') then
    raise exception 'Not an active member of this room';
  end if;

  return query
  select
    c.id,
    sc.id,
    sc.slug,
    sc.name,
    sc.emoji,
    sc.color_hex,
    sc.tagline,
    sc.is_lead,
    sc.sort_order,
    c.user_id,
    c.is_ai,
    p.display_name,
    c.best_performance_count,
    c.game_points,
    case when c.user_id = v_uid then sc.secret_goal else null end
  from public.scene_cast c
  join public.scene_sessions s on s.id = c.session_id
  join public.scene_characters sc on sc.id = c.character_id
  left join public.profiles p on p.user_id = c.user_id
  where s.room_id = p_room_id
  order by sc.sort_order, sc.name;
end;
$$;

-- ── 3. In-app notification when a scene goes live ──────────────────────────
-- Push delivery is handled by the send_battle_notification webhook branch
-- (push-only there — this trigger owns the in-app row, so no duplicates).
-- Act-end notifications are inserted by the Edge Function directly (it knows
-- the Best Performance winner).

create or replace function public.notify_scene_started()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status = 'casting' and new.status = 'live' then
    insert into public.notifications (user_id, type, title, body, data)
    select c.user_id,
           'scene_started',
           '🎬 The scene has started!',
           coalesce(p.name, 'Your scene') || ' is live — get in character.',
           jsonb_build_object('room_id', new.room_id, 'session_id', new.id)
    from public.scene_cast c
    left join public.scene_packs p on p.id = new.pack_id
    where c.session_id = new.id
      and c.user_id is not null
      and c.user_id <> new.created_by;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notify_scene_started on public.scene_sessions;
create trigger trg_notify_scene_started
  after update on public.scene_sessions
  for each row execute function public.notify_scene_started();
