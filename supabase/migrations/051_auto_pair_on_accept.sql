-- 051_auto_pair_on_accept.sql
-- Accepting a friend auto-creates that pair's couple row (the per-pair
-- container), and the join-by-code RPC no longer blocks users who are already
-- in a couple — so a user can connect with many friends.
-- Run AFTER 050 (needs couples_unique_pair + friendship_id).

-- 1. Trigger: when a friendship becomes 'accepted', ensure a couple exists.
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
  insert into public.couples (user_a_id, user_b_id, invite_code, linked_at, friendship_id)
  values (v_lo, v_hi, v_code, now(), new.id)
  on conflict (least(user_a_id, user_b_id), greatest(user_a_id, user_b_id))
    where (user_b_id is not null)
  do nothing;
  return new;
end;
$$;

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

-- 2. Allow joining additional couples by code (drop the single-couple gate).
drop function if exists public.join_couple_by_code(text, uuid);

create or replace function public.join_couple_by_code(
  p_invite_code text,
  p_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_couple record;
begin
  if p_user_id is null then
    return jsonb_build_object('error', 'not_authenticated');
  end if;
  if p_invite_code is null or trim(p_invite_code) = '' then
    return jsonb_build_object('error', 'invalid_code');
  end if;

  select * into v_couple
    from couples
    where invite_code = upper(trim(p_invite_code));

  if v_couple is null then
    return jsonb_build_object('error', 'not_found');
  end if;
  if v_couple.user_a_id = p_user_id then
    return jsonb_build_object('error', 'own_code');
  end if;
  if v_couple.user_b_id is not null then
    return jsonb_build_object('error', 'already_linked');
  end if;

  update couples
    set user_b_id = p_user_id,
        linked_at = now()
    where id = v_couple.id
      and user_b_id is null
    returning * into v_couple;

  if v_couple is null then
    return jsonb_build_object('error', 'already_linked');
  end if;

  -- Record the friendship too so the pair shows up in the friends list.
  insert into public.user_friends (user_a_id, user_b_id, status, requested_by)
  values (least(v_couple.user_a_id, v_couple.user_b_id),
          greatest(v_couple.user_a_id, v_couple.user_b_id),
          'accepted', p_user_id)
  on conflict (user_a_id, user_b_id) do update set status = 'accepted';

  return to_jsonb(v_couple);
end;
$$;
