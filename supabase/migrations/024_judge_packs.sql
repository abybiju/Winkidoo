-- 024: Themed Battle Packs
-- Central entity grouping themed judges, dares, games, and narrative under one umbrella.
-- Supports brand partnerships (movie studios provide character skins for judge personas).

-- ── Pack catalog ──
create table public.judge_packs (
  id                  uuid primary key default gen_random_uuid(),
  slug                text not null unique,
  name                text not null,
  tagline             text,
  description         text,
  cover_asset_path    text,
  primary_color_hex   text,
  secondary_color_hex text,
  is_active           boolean default false,
  is_premium          boolean default false,
  season_start        timestamptz,
  season_end          timestamptz,
  bp_multiplier       numeric(3,2) default 1.0,
  sort_order          int default 0,
  brand_partner       text,
  brand_metadata      jsonb default '{}'::jsonb,
  created_at          timestamptz default now()
);

-- ── Per-pack judge persona overrides ──
create table public.judge_pack_judges (
  id                          uuid primary key default gen_random_uuid(),
  pack_id                     uuid not null references judge_packs(id) on delete cascade,
  judge_persona               text not null,
  override_name               text,
  override_tagline            text,
  override_avatar_path        text,
  override_primary_color_hex  text,
  override_persona_prompt     text,
  override_how_to_impress     text,
  sort_order                  int default 0,
  constraint unique_pack_judge unique (pack_id, judge_persona)
);

-- ── Pack-themed dare templates ──
create table public.pack_dare_templates (
  id          uuid primary key default gen_random_uuid(),
  pack_id     uuid not null references judge_packs(id) on delete cascade,
  category    text not null,
  prompt_hint text not null,
  sort_order  int default 0
);

-- ── Couple's active pack (one at a time) ──
create table public.couple_active_pack (
  couple_id    uuid primary key references public.couples(id) on delete cascade,
  pack_id      uuid references judge_packs(id) on delete set null,
  activated_at timestamptz default now()
);

-- ── Add nullable pack_id to existing tables (backward compatible) ──
alter table public.daily_dares add column if not exists pack_id uuid references judge_packs(id) on delete set null;
alter table public.surprises add column if not exists pack_id uuid references judge_packs(id) on delete set null;
alter table public.quests add column if not exists pack_id uuid references judge_packs(id) on delete set null;
alter table public.judge_collectibles add column if not exists pack_id uuid references judge_packs(id) on delete set null;
alter table public.judge_memory add column if not exists pack_id uuid references judge_packs(id) on delete set null;

-- ── Indexes ──
create index idx_judge_packs_active on judge_packs(is_active) where is_active = true;
create index idx_pack_judges_pack on judge_pack_judges(pack_id);
create index idx_pack_dare_templates_pack on pack_dare_templates(pack_id);

-- ── RLS ──
alter table public.judge_packs enable row level security;
alter table public.judge_pack_judges enable row level security;
alter table public.pack_dare_templates enable row level security;
alter table public.couple_active_pack enable row level security;

-- Pack catalog: all authenticated users can read
create policy "Authenticated users can read packs"
  on public.judge_packs for select using (auth.role() = 'authenticated');

create policy "Authenticated users can read pack judges"
  on public.judge_pack_judges for select using (auth.role() = 'authenticated');

create policy "Authenticated users can read pack dare templates"
  on public.pack_dare_templates for select using (auth.role() = 'authenticated');

-- Couple active pack: couple members can read/write
create policy "Users can read their active pack"
  on public.couple_active_pack for select using (
    couple_id in (select id from couples where user_a_id = auth.uid() or user_b_id = auth.uid())
  );

create policy "Users can set their active pack"
  on public.couple_active_pack for insert with check (
    couple_id in (select id from couples where user_a_id = auth.uid() or user_b_id = auth.uid())
  );

create policy "Users can update their active pack"
  on public.couple_active_pack for update using (
    couple_id in (select id from couples where user_a_id = auth.uid() or user_b_id = auth.uid())
  );

-- ── Seed: Valentine Vibes pack ──
insert into public.judge_packs (slug, name, tagline, description, primary_color_hex, secondary_color_hex, is_active, bp_multiplier, sort_order)
values (
  'valentine_vibes',
  'Valentine Vibes',
  'Love is in the air...',
  'A romantic themed pack with love-struck judges, heartfelt dares, and a warm pink glow. Perfect for date night.',
  '#FF6B9D',
  '#FFD1E3',
  true,
  1.5,
  1
);

-- Seed pack judge overrides for Valentine Vibes
insert into public.judge_pack_judges (pack_id, judge_persona, override_name, override_tagline, override_persona_prompt, override_how_to_impress, sort_order)
select
  jp.id,
  'sassy_cupid',
  'Cupid d''Amour',
  'Struck by the arrow of love.',
  'You are Cupid d''Amour — Sassy Cupid in full Valentine mode. You speak in love metaphors, reference roses, chocolates, and candlelit dinners. Extra romantic, extra dramatic. Use heart emojis generously. Still sassy, but wrapped in Valentine''s silk.',
  'I want grand romantic gestures — poetry, vulnerability, and something that makes my heart flutter. Think candlelit confessions, not grocery-list compliments.',
  1
from public.judge_packs jp where jp.slug = 'valentine_vibes';

insert into public.judge_pack_judges (pack_id, judge_persona, override_name, override_tagline, override_persona_prompt, override_how_to_impress, sort_order)
select
  jp.id,
  'poetic_romantic',
  'The Bard of Hearts',
  'Where every word is a love letter.',
  'You are The Bard of Hearts — the Poetic Romantic wrapped in Valentine elegance. Speak exclusively in love sonnets and iambic pentameter. Reference Shakespeare''s love sonnets, Rumi, and Pablo Neruda. Your words drip with honey and rose water.',
  'I want words that could be carved into marble — timeless declarations of love. Quote the greats or become one yourself.',
  2
from public.judge_packs jp where jp.slug = 'valentine_vibes';

-- Seed dare templates for Valentine Vibes
insert into public.pack_dare_templates (pack_id, category, prompt_hint, sort_order)
select jp.id, 'love_letter', 'Generate a dare involving handwritten love letters, poetic confessions, or romantic declarations. Think Valentine''s Day energy.', 1
from public.judge_packs jp where jp.slug = 'valentine_vibes';

insert into public.pack_dare_templates (pack_id, category, prompt_hint, sort_order)
select jp.id, 'date_night', 'Generate a dare about planning or describing a dream date night. Include specific romantic details — candles, music, food.', 2
from public.judge_packs jp where jp.slug = 'valentine_vibes';

insert into public.pack_dare_templates (pack_id, category, prompt_hint, sort_order)
select jp.id, 'sweet_nothings', 'Generate a dare involving whispered sweet nothings, compliments, or describing what you love about your partner using only metaphors.', 3
from public.judge_packs jp where jp.slug = 'valentine_vibes';
