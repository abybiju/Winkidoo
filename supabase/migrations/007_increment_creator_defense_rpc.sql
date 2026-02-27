-- Atomic increment of creator_defense_count to avoid race conditions when both clients send.
-- Uses security invoker so RLS applies: only callers who can update the surprise row will succeed.
create or replace function public.increment_surprise_creator_defense(p_surprise_id uuid)
returns void
language sql
security invoker
set search_path = public
as $$
  update public.surprises
  set creator_defense_count = creator_defense_count + 1,
      last_activity_at = now()
  where id = p_surprise_id;
$$;
