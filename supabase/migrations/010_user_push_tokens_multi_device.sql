-- Multi-device: one row per device (push_token unique), user can have multiple tokens.
-- Enables sending to all of a user's devices.
alter table public.user_push_tokens
  add column if not exists id uuid not null default gen_random_uuid();

alter table public.user_push_tokens drop constraint if exists user_push_tokens_pkey;
alter table public.user_push_tokens add primary key (id);

create unique index if not exists user_push_tokens_push_token_key
  on public.user_push_tokens (push_token) where push_token is not null;

comment on table public.user_push_tokens is 'Device push tokens for battle-aware notifications; one row per device (push_token unique), user can have multiple devices.';
