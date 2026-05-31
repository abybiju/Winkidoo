-- 049_profiles_identity_and_search.sql
-- Make users searchable by name for the in-app friend system.
--
-- The friend backend (user_friends + FriendService) already exists, but the
-- profiles table only stored avatar fields, so users could not be found by
-- name. Add a searchable display_name, backfill it from auth metadata, and add
-- a security-definer search RPC.

-- 1. display_name column + fuzzy search index
alter table public.profiles
  add column if not exists display_name text;

create extension if not exists pg_trgm;

create index if not exists idx_profiles_display_name_trgm
  on public.profiles using gin (display_name gin_trgm_ops);

-- 2. Backfill display_name for every auth user (creating a profiles row if the
--    user has none yet) from their metadata 'name', falling back to email local part.
insert into public.profiles (user_id, display_name)
select u.id,
       coalesce(nullif(trim(u.raw_user_meta_data->>'name'), ''),
                split_part(u.email, '@', 1))
from auth.users u
on conflict (user_id) do update
  set display_name = coalesce(public.profiles.display_name, excluded.display_name);

-- 3. Search RPC — case-insensitive partial match on display_name, excludes self.
--    security definer so it can read all profiles regardless of the caller's RLS.
create or replace function public.search_users_by_name(p_query text)
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  avatar_mode text,
  avatar_asset_path text
)
language sql
security definer
set search_path = public
as $$
  select p.user_id, p.display_name, p.avatar_url, p.avatar_mode, p.avatar_asset_path
  from public.profiles p
  where p.user_id <> auth.uid()
    and p.display_name is not null
    and trim(p_query) <> ''
    and p.display_name ilike '%' || trim(p_query) || '%'
  order by p.display_name
  limit 20;
$$;

grant execute on function public.search_users_by_name(text) to authenticated;

-- 4. Track who SENT each friend request. user_friends sorts user_a/user_b by
--    UUID (FriendService.sendFriendRequest), which loses the requester's
--    identity — so we can't tell incoming from outgoing. Add requested_by.
alter table public.user_friends
  add column if not exists requested_by uuid references auth.users(id) on delete set null;

