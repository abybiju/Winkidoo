-- 025: Couple Mini-Games
-- Quick daily 2-player games that rotate alongside dares.
-- Game types: would_you_rather, love_trivia, caption_this, finish_my_sentence.

-- ── Game type catalog ──
create table public.mini_game_types (
  id          text primary key,
  name        text not null,
  description text,
  icon_name   text,
  is_active   boolean default true,
  sort_order  int default 0
);

-- Seed game types
insert into public.mini_game_types (id, name, description, icon_name, sort_order) values
  ('would_you_rather', 'Would You Rather', 'Pick from two AI-generated romantic dilemmas', 'compare_arrows', 1),
  ('love_trivia', 'Love Trivia', 'AI asks couple-specific questions using your battle history', 'quiz', 2),
  ('caption_this', 'Caption This', 'Both caption a funny scenario — AI picks the winner', 'subtitles', 3),
  ('finish_my_sentence', 'Finish My Sentence', 'One starts a sentence, the other finishes it', 'edit_note', 4);

-- ── Daily mini-games (one per couple per day, parallel to daily_dares) ──
create table public.daily_mini_games (
  id                  uuid primary key default gen_random_uuid(),
  couple_id           uuid not null references public.couples(id) on delete cascade,
  game_date           date not null default current_date,
  game_type           text not null references mini_game_types(id),
  judge_persona       text not null,
  pack_id             uuid references judge_packs(id) on delete set null,

  -- AI-generated game content
  game_prompt         text not null,
  game_options        jsonb,

  -- Partner responses (encrypted)
  user_a_response     text,
  user_a_submitted_at timestamptz,
  user_b_response     text,
  user_b_submitted_at timestamptz,

  -- AI grading
  grade_commentary    text,
  grade_score         int,
  grade_emoji         text,
  graded_at           timestamptz,

  status              text not null default 'pending',
  expires_at          timestamptz not null default (current_date + interval '30 hours'),
  created_at          timestamptz not null default now(),

  constraint unique_couple_game_date unique (couple_id, game_date)
);

-- ── Pack-themed mini-game templates ──
create table public.pack_mini_game_templates (
  id          uuid primary key default gen_random_uuid(),
  pack_id     uuid not null references judge_packs(id) on delete cascade,
  game_type   text not null references mini_game_types(id),
  prompt_hint text not null,
  example_prompt text,
  sort_order  int default 0
);

-- Indexes
create index idx_mini_games_couple_date on daily_mini_games(couple_id, game_date desc);
create index idx_mini_games_active on daily_mini_games(status) where status in ('pending', 'partial');
create index idx_pack_mini_templates on pack_mini_game_templates(pack_id);

-- RLS
alter table public.mini_game_types enable row level security;
alter table public.daily_mini_games enable row level security;
alter table public.pack_mini_game_templates enable row level security;

create policy "Authenticated users can read game types"
  on public.mini_game_types for select using (auth.role() = 'authenticated');

create policy "Users can view their couple games"
  on public.daily_mini_games for select using (
    couple_id in (select id from couples where user_a_id = auth.uid() or user_b_id = auth.uid())
  );

create policy "Users can insert games for their couple"
  on public.daily_mini_games for insert with check (
    couple_id in (select id from couples where user_a_id = auth.uid() or user_b_id = auth.uid())
  );

create policy "Users can update their couple games"
  on public.daily_mini_games for update using (
    couple_id in (select id from couples where user_a_id = auth.uid() or user_b_id = auth.uid())
  );

create policy "Authenticated users can read pack game templates"
  on public.pack_mini_game_templates for select using (auth.role() = 'authenticated');

-- Add to Realtime publication
alter publication supabase_realtime add table public.daily_mini_games;

-- Seed Valentine Vibes mini-game templates
insert into public.pack_mini_game_templates (pack_id, game_type, prompt_hint, sort_order)
select jp.id, 'would_you_rather', 'Generate romantic Valentine-themed dilemmas about date nights, gifts, and love languages.', 1
from public.judge_packs jp where jp.slug = 'valentine_vibes';

insert into public.pack_mini_game_templates (pack_id, game_type, prompt_hint, sort_order)
select jp.id, 'caption_this', 'Generate romantic Valentine scenarios involving candlelit dinners, surprise proposals, or love letters gone wrong.', 2
from public.judge_packs jp where jp.slug = 'valentine_vibes';
