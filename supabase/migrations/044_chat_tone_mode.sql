-- Migration 044: Add tone_id column to character_chat_messages for mood/tone transformation.

alter table public.character_chat_messages
  add column tone_id text default null;

create index idx_chat_messages_tone on character_chat_messages(tone_id) where tone_id is not null;
