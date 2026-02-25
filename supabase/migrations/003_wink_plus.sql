-- Wink+ subscription: couple-level premium until date
-- When now() < wink_plus_until, the couple has Wink+ (more free attempts, all personas).

alter table public.couples
  add column if not exists wink_plus_until timestamptz;

comment on column public.couples.wink_plus_until is 'When set and in the future, this couple has Wink+ (premium).';
