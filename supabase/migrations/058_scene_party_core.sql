-- Migration 058: Scene Party core — theme packs, sessions, cast, bot messages
-- Run in Supabase Dashboard → SQL Editor (before 059)
--
-- Scene Party = themed group roleplay on top of character chat. A scene room
-- IS a character_chat_rooms row (type 'group') with a 1:1 scene_sessions row.
-- Content tables (packs/characters/acts) are client read-only and seeded via
-- SQL (judge_packs pattern) so new packs ship with zero app release.
-- Bot messages (director/castmate/game_card/system) are inserted ONLY by the
-- scene-director Edge Function via service role — clients cannot forge them.

-- ── 1. Content tables (read-only to clients) ──────────────────────────────

create table public.scene_packs (
  id                  uuid primary key default gen_random_uuid(),
  slug                text not null unique,
  name                text not null,
  tagline             text,
  description         text,
  emoji               text,
  primary_color_hex   text,
  secondary_color_hex text,
  setting_prompt      text not null,          -- world bible fed to Director/castmates
  opening_line        text,                   -- static fallback opener if AI fails
  act_count           int  not null default 3 check (act_count between 1 and 5),
  min_players         int  not null default 1,
  max_players         int  not null default 6,
  is_active           boolean not null default false,
  is_premium          boolean not null default false,  -- launch: all false; Wink+ gate hook
  season_start        timestamptz,
  season_end          timestamptz,
  sort_order          int not null default 0,
  created_at          timestamptz not null default now()
);

create table public.scene_characters (
  id              uuid primary key default gen_random_uuid(),
  pack_id         uuid not null references public.scene_packs(id) on delete cascade,
  slug            text not null,
  name            text not null,
  emoji           text,
  color_hex       text,
  tagline         text,
  voice_prompt    text not null,   -- maps into CharacterPreset.systemPrompt (client transform)
  castmate_prompt text not null,   -- full CHARACTER SHEET for AI castmate replies
  secret_goal     text,            -- visible only to the claiming player
  is_lead         boolean not null default false,
  sort_order      int not null default 0,
  constraint unique_pack_character unique (pack_id, slug)
);

create table public.scene_act_templates (
  id                uuid primary key default gen_random_uuid(),
  pack_id           uuid not null references public.scene_packs(id) on delete cascade,
  act_number        int  not null,
  title             text not null,
  director_brief    text not null,      -- what this act must accomplish
  twist_hints       jsonb not null default '[]'::jsonb, -- twist ideas + Fate Card roles
  min_user_messages int  not null default 12,           -- act-advance threshold
  constraint unique_pack_act unique (pack_id, act_number)
);

alter table public.scene_packs enable row level security;
alter table public.scene_characters enable row level security;
alter table public.scene_act_templates enable row level security;

-- Content is world-readable to signed-in users; only service role / SQL editor writes.
create policy "Authenticated read scene packs" on public.scene_packs
  for select using (auth.role() = 'authenticated');
create policy "Authenticated read scene characters" on public.scene_characters
  for select using (auth.role() = 'authenticated');
create policy "Authenticated read scene acts" on public.scene_act_templates
  for select using (auth.role() = 'authenticated');

-- ── 2. Session state ──────────────────────────────────────────────────────

create table public.scene_sessions (
  id                   uuid primary key default gen_random_uuid(),
  room_id              uuid not null unique references public.character_chat_rooms(id) on delete cascade,
  pack_id              uuid not null references public.scene_packs(id),
  status               text not null default 'casting'
                         check (status in ('casting','live','ended')),
  current_act          int  not null default 0,      -- 0 = not started
  act_started_at       timestamptz,
  user_msgs_in_act     int  not null default 0,      -- maintained by trigger (060)
  msgs_since_director  int  not null default 0,
  msgs_since_castmate  int  not null default 0,
  castmate_msgs_in_act int  not null default 0,      -- per-act castmate cap counter
  version              int  not null default 0,      -- CAS token for director turns
  director_busy_until  timestamptz,                  -- turn lease (self-heals stuck turns)
  created_by           uuid not null references auth.users(id) on delete cascade,
  created_at           timestamptz not null default now(),
  ended_at             timestamptz
);
create index idx_scene_sessions_room on public.scene_sessions(room_id);

create table public.scene_cast (
  id                     uuid primary key default gen_random_uuid(),
  session_id             uuid not null references public.scene_sessions(id) on delete cascade,
  character_id           uuid not null references public.scene_characters(id),
  user_id                uuid references auth.users(id) on delete cascade,  -- NULL = AI castmate
  is_ai                  boolean not null default true,
  best_performance_count int not null default 0,
  game_points            int not null default 0,
  claimed_at             timestamptz not null default now(),
  constraint unique_session_character unique (session_id, character_id),
  -- NULL user_ids are distinct under UNIQUE: many AI rows coexist, each human
  -- holds at most one character per session.
  constraint unique_session_user unique (session_id, user_id),
  constraint chk_ai_or_user check ((is_ai and user_id is null) or (not is_ai and user_id is not null))
);
create index idx_scene_cast_session on public.scene_cast(session_id);

alter table public.scene_sessions enable row level security;
alter table public.scene_cast enable row level security;

-- Member-scoped reads through room membership (non-recursive, 056 pattern).
-- No client INSERT/UPDATE policies: all writes go through the SECURITY DEFINER
-- RPCs below or the scene-director Edge Function (service role).
create policy "Room members read scene sessions" on public.scene_sessions
  for select using (
    room_id in (select room_id from public.character_chat_members
                where user_id = auth.uid() and status = 'active'));

create policy "Room members read scene cast" on public.scene_cast
  for select using (
    session_id in (select s.id from public.scene_sessions s
                   join public.character_chat_members m on m.room_id = s.room_id
                   where m.user_id = auth.uid() and m.status = 'active'));

-- ── 3. character_chat_messages: bot message support ───────────────────────

alter table public.character_chat_messages
  add column if not exists message_type text not null default 'user'
    check (message_type in ('user','director','castmate','game_card','system')),
  add column if not exists payload jsonb;

alter table public.character_chat_messages alter column sender_id drop not null;

alter table public.character_chat_messages add constraint chk_sender_by_type check (
  (message_type = 'user' and sender_id is not null)
  or (message_type <> 'user' and sender_id is null)
);

-- Clients may ONLY create user rows; bot rows come from the Edge Function
-- (service role bypasses RLS). SELECT/UPDATE policies need no change: reads
-- are membership-scoped, and updates require sender_id = auth.uid() which a
-- NULL sender never satisfies.
drop policy if exists "Room members can insert messages" on public.character_chat_messages;
create policy "Room members can insert messages"
  on public.character_chat_messages for insert with check (
    message_type = 'user'
    and sender_id = auth.uid()
    and room_id in (select room_id from public.character_chat_members
                    where user_id = auth.uid() and status = 'active'));

-- ── 4. Session RPCs ────────────────────────────────────────────────────────

-- Creates the scene: group room (056 friend-gating copied), session row in
-- 'casting', and one all-AI cast row per pack character. Returns room_id.
create or replace function public.create_scene_session(
  p_pack_id uuid,
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
  v_session_id uuid;
  v_pack public.scene_packs%rowtype;
  v_mid uuid;
  v_is_premium_ok boolean;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_pack from public.scene_packs where id = p_pack_id;
  if not found or not v_pack.is_active then
    raise exception 'Scene pack not available';
  end if;
  if v_pack.season_start is not null and now() < v_pack.season_start then
    raise exception 'Scene pack not in season';
  end if;
  if v_pack.season_end is not null and now() > v_pack.season_end then
    raise exception 'Scene pack not in season';
  end if;

  -- Premium hook (dormant at launch — all packs free). A pack flipped to
  -- premium requires the caller to sit in any couple with active Wink+.
  if v_pack.is_premium then
    select exists (
      select 1 from public.couples c
      where (c.user_a_id = v_uid or c.user_b_id = v_uid)
        and c.wink_plus_until is not null and c.wink_plus_until > now()
    ) into v_is_premium_ok;
    if not v_is_premium_ok then
      raise exception 'PREMIUM_REQUIRED';
    end if;
  end if;

  insert into public.character_chat_rooms (type, name, created_by)
    values ('group',
            coalesce(nullif(trim(coalesce(p_name, '')), ''), v_pack.name),
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

  insert into public.scene_sessions (room_id, pack_id, created_by)
    values (v_room_id, p_pack_id, v_uid)
    returning id into v_session_id;

  -- Every character starts as an AI castmate; humans claim from this pool.
  insert into public.scene_cast (session_id, character_id, is_ai)
    select v_session_id, sc.id, true
    from public.scene_characters sc
    where sc.pack_id = p_pack_id;

  return v_room_id;
end;
$$;

grant execute on function public.create_scene_session(uuid, text, uuid[]) to authenticated;

-- Claim (or re-pick) a character. Humans can never displace humans; the
-- caller's previous claim is released back to AI. Race-safe: the UNIQUE
-- constraints make the second concurrent claimer fail cleanly.
create or replace function public.claim_scene_character(
  p_room_id uuid,
  p_character_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_session_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  select s.id into v_session_id
  from public.scene_sessions s
  join public.character_chat_members m
    on m.room_id = s.room_id and m.user_id = v_uid and m.status = 'active'
  where s.room_id = p_room_id;
  if v_session_id is null then
    raise exception 'No scene in this room or not a member';
  end if;

  if exists (select 1 from public.scene_cast
             where session_id = v_session_id and character_id = p_character_id
               and is_ai = false and user_id <> v_uid) then
    raise exception 'CHARACTER_TAKEN';
  end if;

  -- Release any previous claim by this user back to AI.
  update public.scene_cast
     set user_id = null, is_ai = true
   where session_id = v_session_id and user_id = v_uid;

  update public.scene_cast
     set user_id = v_uid, is_ai = false, claimed_at = now()
   where session_id = v_session_id and character_id = p_character_id
     and is_ai = true;
  if not found then
    raise exception 'CHARACTER_TAKEN';
  end if;
end;
$$;

grant execute on function public.claim_scene_character(uuid, uuid) to authenticated;

-- Cast roster with character + player identity. secret_goal only for own row.
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

grant execute on function public.get_scene_cast(uuid) to authenticated;

-- ── 5. Realtime ────────────────────────────────────────────────────────────

alter publication supabase_realtime add table public.scene_sessions;
