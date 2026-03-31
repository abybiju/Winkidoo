-- 032: AI Character Chat — rooms, members, messages, friends
-- Real-time chat where messages are AI-transformed into character speaking styles.
-- Supports couple, 1-on-1 friend, and group chats.

-- ── Chat rooms ──
create table public.character_chat_rooms (
  id          uuid primary key default gen_random_uuid(),
  type        text not null default 'friend' check (type in ('couple', 'friend', 'group')),
  name        text,  -- nullable; used for group chats
  invite_code text unique default encode(gen_random_bytes(6), 'hex'),
  created_by  uuid not null references auth.users(id) on delete cascade,
  created_at  timestamptz default now()
);

-- ── Room membership ──
create table public.character_chat_members (
  id        uuid primary key default gen_random_uuid(),
  room_id   uuid not null references character_chat_rooms(id) on delete cascade,
  user_id   uuid not null references auth.users(id) on delete cascade,
  role      text not null default 'member' check (role in ('admin', 'member')),
  joined_at timestamptz default now(),
  constraint unique_room_member unique (room_id, user_id)
);

-- ── Chat messages ──
create table public.character_chat_messages (
  id                    uuid primary key default gen_random_uuid(),
  room_id               uuid not null references character_chat_rooms(id) on delete cascade,
  sender_id             uuid not null references auth.users(id) on delete cascade,
  original_content      text not null,
  transformed_content   text,  -- null when character_id = 'normal'
  character_id          text not null default 'normal',
  character_name        text not null default 'Normal',
  is_transforming       boolean not null default false,
  created_at            timestamptz default now()
);

-- ── Friends ──
create table public.user_friends (
  id         uuid primary key default gen_random_uuid(),
  user_a_id  uuid not null references auth.users(id) on delete cascade,
  user_b_id  uuid not null references auth.users(id) on delete cascade,
  status     text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz default now(),
  constraint unique_friendship unique (user_a_id, user_b_id),
  constraint no_self_friend check (user_a_id <> user_b_id)
);

-- ── Indexes ──
create index idx_chat_rooms_created_by on character_chat_rooms(created_by);
create index idx_chat_members_user on character_chat_members(user_id);
create index idx_chat_members_room on character_chat_members(room_id);
create index idx_chat_messages_room_time on character_chat_messages(room_id, created_at);
create index idx_chat_messages_sender on character_chat_messages(sender_id);
create index idx_friends_a on user_friends(user_a_id);
create index idx_friends_b on user_friends(user_b_id);

-- ── RLS ──
alter table public.character_chat_rooms enable row level security;
alter table public.character_chat_members enable row level security;
alter table public.character_chat_messages enable row level security;
alter table public.user_friends enable row level security;

-- Rooms: members can read
create policy "Room members can read rooms"
  on public.character_chat_rooms for select using (
    id in (select room_id from character_chat_members where user_id = auth.uid())
  );

-- Rooms: any authenticated user can create
create policy "Authenticated users can create rooms"
  on public.character_chat_rooms for insert
  with check (auth.uid() = created_by);

-- Members: users can always read their own membership rows
create policy "Users can read own memberships"
  on public.character_chat_members for select using (user_id = auth.uid());

-- Members: users can see other members in rooms they belong to
create policy "Users can read co-members"
  on public.character_chat_members for select using (
    exists (
      select 1 from character_chat_rooms r
      where r.id = room_id
      and r.id in (select m.room_id from character_chat_members m where m.user_id = auth.uid())
    )
  );

-- Members: room admin or self-join via invite
create policy "Users can join rooms"
  on public.character_chat_members for insert
  with check (auth.uid() = user_id);

-- Members: admin can remove, or user can leave
create policy "Users can leave or admin can remove"
  on public.character_chat_members for delete using (
    user_id = auth.uid() or
    room_id in (
      select room_id from character_chat_members
      where user_id = auth.uid() and role = 'admin'
    )
  );

-- Messages: room members can read
create policy "Room members can read messages"
  on public.character_chat_messages for select using (
    room_id in (select room_id from character_chat_members where user_id = auth.uid())
  );

-- Messages: room members can insert
create policy "Room members can insert messages"
  on public.character_chat_messages for insert
  with check (
    sender_id = auth.uid() and
    room_id in (select room_id from character_chat_members where user_id = auth.uid())
  );

-- Messages: sender can update their own (for transform completion)
create policy "Sender can update own messages"
  on public.character_chat_messages for update using (sender_id = auth.uid());

-- Friends: users can see their own friendships
create policy "Users can read own friendships"
  on public.user_friends for select using (
    user_a_id = auth.uid() or user_b_id = auth.uid()
  );

-- Friends: authenticated users can send friend requests
create policy "Users can send friend requests"
  on public.user_friends for insert
  with check (user_a_id = auth.uid() or user_b_id = auth.uid());

-- Friends: either party can update (accept) or delete (unfriend)
create policy "Users can update own friendships"
  on public.user_friends for update using (
    user_a_id = auth.uid() or user_b_id = auth.uid()
  );

create policy "Users can delete own friendships"
  on public.user_friends for delete using (
    user_a_id = auth.uid() or user_b_id = auth.uid()
  );

-- Profiles: allow authenticated users to search other users by name/email
-- (profiles table already exists from migration 010 — add read policy for search)
create policy "Authenticated users can search profiles"
  on public.profiles for select using (auth.role() = 'authenticated');

-- ── Realtime ──
alter publication supabase_realtime add table public.character_chat_messages;
