-- Surprise type: text (default), photo, or voice. Media stored in Storage, path in DB.
alter table public.surprises
  add column if not exists surprise_type text not null default 'text' check (surprise_type in ('text', 'photo', 'voice'));

alter table public.surprises
  add column if not exists content_storage_path text;

comment on column public.surprises.surprise_type is 'text = content in content_encrypted; photo = file in Storage, path in content_storage_path';
comment on column public.surprises.content_storage_path is 'Supabase Storage path for photo (and later voice/video) content';

-- For photo type, content_encrypted can be empty; app may store placeholder.
-- RLS unchanged: couple members only. Create Storage bucket "surprises" with RLS in dashboard:
-- allow read for couple members, insert/update for couple members.
