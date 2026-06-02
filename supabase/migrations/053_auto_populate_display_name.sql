-- 053_auto_populate_display_name.sql
-- Ensure EVERY user has a display_name. Until now display_name was written only
-- when a user manually edited their profile (profile_screen), so most users showed
-- as "Winkidoo user" in the friends list, had no name in chat, and were UNFINDABLE
-- in search (search_users_by_name filters `display_name is not null`). 049's backfill
-- was one-time, so every signup since then has a null name.
--
-- Fix: a signup trigger that seeds the profile name, plus a re-run of the backfill.

-- 1. Signup trigger: seed a profiles row with a display_name on every new auth user.
--    Name priority: metadata 'name' → metadata 'full_name' (OAuth) → email local part.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id, display_name)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data->>'name'), ''),
      nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
      split_part(new.email, '@', 1)
    )
  )
  on conflict (user_id) do update
    set display_name = coalesce(
      nullif(trim(public.profiles.display_name), ''),
      excluded.display_name
    );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2. Backfill users still missing a name (everyone who signed up since 049).
insert into public.profiles (user_id, display_name)
select u.id,
       coalesce(nullif(trim(u.raw_user_meta_data->>'name'), ''),
                nullif(trim(u.raw_user_meta_data->>'full_name'), ''),
                split_part(u.email, '@', 1))
from auth.users u
on conflict (user_id) do update
  set display_name = coalesce(
    nullif(trim(public.profiles.display_name), ''),
    excluded.display_name
  );
