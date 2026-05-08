-- Secure RPC for joining a couple by invite code.
-- Validates: code exists, slot is open, caller isn't the creator,
-- caller isn't already in another couple.
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
  v_existing_couple_id uuid;
begin
  -- Validate inputs
  if p_user_id is null then
    return jsonb_build_object('error', 'not_authenticated');
  end if;

  if p_invite_code is null or trim(p_invite_code) = '' then
    return jsonb_build_object('error', 'invalid_code');
  end if;

  -- Check if user is already in a couple
  select id into v_existing_couple_id
    from couples
    where user_a_id = p_user_id or user_b_id = p_user_id
    limit 1;

  if v_existing_couple_id is not null then
    return jsonb_build_object('error', 'already_in_couple');
  end if;

  -- Find the couple by invite code
  select * into v_couple
    from couples
    where invite_code = upper(trim(p_invite_code));

  if v_couple is null then
    return jsonb_build_object('error', 'not_found');
  end if;

  -- Prevent joining your own couple
  if v_couple.user_a_id = p_user_id then
    return jsonb_build_object('error', 'own_code');
  end if;

  -- Check if slot is still open
  if v_couple.user_b_id is not null then
    return jsonb_build_object('error', 'already_linked');
  end if;

  -- Join the couple
  update couples
    set user_b_id = p_user_id,
        linked_at = now()
    where id = v_couple.id
      and user_b_id is null  -- prevent race condition
    returning * into v_couple;

  if v_couple is null then
    return jsonb_build_object('error', 'already_linked');
  end if;

  return to_jsonb(v_couple);
end;
$$;
