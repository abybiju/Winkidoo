-- 050_friend_pairs.sql
-- Make `couples` a per-friend-pair container: a user may now belong to many
-- couples (one per accepted friend). This migration is backward-compatible —
-- existing linked couples keep working and become friend pairs.
--
-- NOTE: run BEFORE 051. If two linked couple rows for the SAME member pair both
-- own surprises, the unique index below will fail — resolve those by hand first
-- (re-pointing surprises would break their encryption, which is keyed on couple_id).

-- 1. Dedupe linked couples that share the same member pair. Keep the row that
--    owns surprises (or the oldest); delete only EMPTY duplicates so encryption
--    stays intact, then the unique index can be created.
with ranked as (
  select c.id,
         least(c.user_a_id, c.user_b_id)  as lo,
         greatest(c.user_a_id, c.user_b_id) as hi,
         (select count(*) from public.surprises s where s.couple_id = c.id) as n_surprises,
         c.created_at
  from public.couples c
  where c.user_b_id is not null
),
keepers as (
  select distinct on (lo, hi) id
  from ranked
  order by lo, hi, n_surprises desc, created_at asc
)
delete from public.couples c
using ranked r
where c.id = r.id
  and r.n_surprises = 0
  and c.id not in (select id from keepers);

-- 2. Link couples back to their friendship row.
alter table public.couples
  add column if not exists friendship_id uuid
    references public.user_friends(id) on delete set null;

-- 3. One couple per unordered member pair (linked couples only).
create unique index if not exists couples_unique_pair
  on public.couples (least(user_a_id, user_b_id), greatest(user_a_id, user_b_id))
  where user_b_id is not null;

-- 4. Backfill user_friends (accepted) for every existing linked couple so they
--    show up in the friends list / avatar rail. user_friends sorts the pair by
--    UUID, so insert least/greatest to match the unique_friendship constraint.
insert into public.user_friends (user_a_id, user_b_id, status, requested_by)
select least(c.user_a_id, c.user_b_id),
       greatest(c.user_a_id, c.user_b_id),
       'accepted',
       c.user_a_id
from public.couples c
where c.user_b_id is not null
on conflict (user_a_id, user_b_id) do nothing;

-- 5. Point each linked couple at its friendship row.
update public.couples c
set friendship_id = uf.id
from public.user_friends uf
where c.user_b_id is not null
  and c.friendship_id is null
  and least(c.user_a_id, c.user_b_id) = uf.user_a_id
  and greatest(c.user_a_id, c.user_b_id) = uf.user_b_id;
