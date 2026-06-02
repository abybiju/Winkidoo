-- 054_search_excludes_existing_friends.sql
-- The "Find friends" search returned people you're ALREADY friends with (or have a
-- pending request to/from), so you could fire duplicate requests. Exclude anyone who
-- already has a user_friends row with the caller (either direction, any status).

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
    and not exists (
      select 1 from public.user_friends uf
      where (uf.user_a_id = auth.uid() and uf.user_b_id = p.user_id)
         or (uf.user_a_id = p.user_id and uf.user_b_id = auth.uid())
    )
  order by p.display_name
  limit 20;
$$;

grant execute on function public.search_users_by_name(text) to authenticated;
