-- Store FCM/APNs device tokens for push notifications. App upserts on login.
create table if not exists public.user_push_tokens (
  user_id uuid primary key references auth.users(id) on delete cascade,
  push_token text,
  push_platform text check (push_platform in ('ios', 'android', 'web')),
  updated_at timestamptz not null default now()
);

comment on table public.user_push_tokens is 'Device push tokens for battle-aware notifications; one row per user (last device wins for V1).';

alter table public.user_push_tokens enable row level security;

drop policy if exists "Users can read own push token" on public.user_push_tokens;
drop policy if exists "Users can insert own push token" on public.user_push_tokens;
drop policy if exists "Users can update own push token" on public.user_push_tokens;

create policy "Users can read own push token"
  on public.user_push_tokens for select
  using (auth.uid() = user_id);

create policy "Users can insert own push token"
  on public.user_push_tokens for insert
  with check (auth.uid() = user_id);

create policy "Users can update own push token"
  on public.user_push_tokens for update
  using (auth.uid() = user_id);
