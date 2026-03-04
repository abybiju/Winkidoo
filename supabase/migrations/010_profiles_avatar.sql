create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  avatar_mode text not null default 'none'
    check (avatar_mode in ('none', 'preset', 'upload')),
  avatar_asset_path text,
  avatar_storage_path text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Users can read own profile row" on public.profiles;
create policy "Users can read own profile row"
  on public.profiles for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own profile row" on public.profiles;
create policy "Users can insert own profile row"
  on public.profiles for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own profile row" on public.profiles;
create policy "Users can update own profile row"
  on public.profiles for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create or replace function public.set_profiles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_profiles_updated_at();

insert into storage.buckets (id, name, public)
values ('profile-avatars', 'profile-avatars', true)
on conflict (id) do nothing;

drop policy if exists "Public read profile avatars" on storage.objects;
create policy "Public read profile avatars"
  on storage.objects for select
  using (bucket_id = 'profile-avatars');

drop policy if exists "Users write own profile avatars" on storage.objects;
create policy "Users write own profile avatars"
  on storage.objects for insert
  with check (
    bucket_id = 'profile-avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users update own profile avatars" on storage.objects;
create policy "Users update own profile avatars"
  on storage.objects for update
  using (
    bucket_id = 'profile-avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'profile-avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
