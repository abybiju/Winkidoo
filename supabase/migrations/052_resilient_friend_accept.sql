-- 052_resilient_friend_accept.sql
-- Fixes "clicking Accept on a friend request does nothing".
--
-- Root cause: the couple-auto-create trigger from 051 runs
--   INSERT INTO couples ... ON CONFLICT (least(..),greatest(..)) WHERE user_b_id IS NOT NULL
-- which requires the `couples_unique_pair` partial index from 050. That index could
-- NOT be created on this DB because duplicate self-pair couple rows exist (rows where
-- user_a_id = user_b_id, so LEAST = GREATEST and the key collides). With the index
-- missing, the trigger throws on every accept and the whole UPDATE rolls back — so the
-- friendship stays 'pending' and nothing visibly happens.
--
-- This migration removes the dependency on that index entirely: the trigger now checks
-- for an existing couple with IF NOT EXISTS instead of ON CONFLICT, and is wrapped in an
-- exception guard so couple-creation can NEVER roll back the accept. Non-destructive:
-- it does not touch the existing (junk) self-pair rows. Idempotent — safe to re-run.

-- 1. Ensure 050's friendship_id column exists (idempotent; does not require the index).
alter table public.couples
  add column if not exists friendship_id uuid
    references public.user_friends(id) on delete set null;

-- 2. Resilient trigger: no ON CONFLICT / no unique-index dependency; never blocks accept.
create or replace function public.create_couple_on_friend_accept()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lo uuid := least(new.user_a_id, new.user_b_id);
  v_hi uuid := greatest(new.user_a_id, new.user_b_id);
  v_code text := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
begin
  begin
    if not exists (
      select 1 from public.couples c
      where c.user_b_id is not null
        and least(c.user_a_id, c.user_b_id) = v_lo
        and greatest(c.user_a_id, c.user_b_id) = v_hi
    ) then
      insert into public.couples (user_a_id, user_b_id, invite_code, linked_at, friendship_id)
      values (v_lo, v_hi, v_code, now(), new.id);
    end if;
  exception when others then
    -- Do NOT block the friendship from being accepted if couple auto-create fails.
    raise warning 'create_couple_on_friend_accept failed for friendship %: %',
      new.id, sqlerrm;
  end;
  return new;
end;
$$;

-- Recreate triggers defensively so this migration is self-contained.
drop trigger if exists trg_couple_on_friend_accept_ins on public.user_friends;
create trigger trg_couple_on_friend_accept_ins
  after insert on public.user_friends
  for each row when (new.status = 'accepted')
  execute function public.create_couple_on_friend_accept();

drop trigger if exists trg_couple_on_friend_accept_upd on public.user_friends;
create trigger trg_couple_on_friend_accept_upd
  after update of status on public.user_friends
  for each row when (new.status = 'accepted' and old.status is distinct from 'accepted')
  execute function public.create_couple_on_friend_accept();

-- 3. Backfill couple rows for already-accepted friendships that don't have one yet
--    (e.g. accepts that silently failed before this fix). NOT EXISTS, not ON CONFLICT.
insert into public.couples (user_a_id, user_b_id, invite_code, linked_at, friendship_id)
select least(uf.user_a_id, uf.user_b_id),
       greatest(uf.user_a_id, uf.user_b_id),
       upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)),
       now(),
       uf.id
from public.user_friends uf
where uf.status = 'accepted'
  and not exists (
    select 1 from public.couples c
    where c.user_b_id is not null
      and least(c.user_a_id, c.user_b_id) = least(uf.user_a_id, uf.user_b_id)
      and greatest(c.user_a_id, c.user_b_id) = greatest(uf.user_a_id, uf.user_b_id)
  );
