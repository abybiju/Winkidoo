-- 026: Story Mode Campaigns
-- Narrative-driven quest chains tied to packs. AI judge plays a character
-- with personality shifts per chapter (persona_mood_override).

-- ── Campaign catalog ──
create table public.campaigns (
  id               uuid primary key default gen_random_uuid(),
  pack_id          uuid references judge_packs(id) on delete set null,
  slug             text not null unique,
  title            text not null,
  subtitle         text,
  description      text,
  cover_asset_path text,
  total_chapters   int not null default 5 check (total_chapters between 2 and 10),
  judge_persona    text not null,
  difficulty_curve text default 'linear',
  is_active        boolean default false,
  is_premium       boolean default false,
  sort_order       int default 0,
  created_at       timestamptz default now()
);

-- ── Campaign chapters (narrative structure) ──
create table public.campaign_chapters (
  id                     uuid primary key default gen_random_uuid(),
  campaign_id            uuid not null references campaigns(id) on delete cascade,
  chapter_number         int not null,
  title                  text not null,
  intro_dialogue         text,
  outro_dialogue         text,
  persona_mood_override  text,
  quest_count            int not null default 3 check (quest_count between 1 and 7),
  difficulty_start       int not null default 1,
  difficulty_end         int not null default 3,
  constraint unique_campaign_chapter unique (campaign_id, chapter_number)
);

-- ── Per-couple campaign progress ──
create table public.couple_campaign_progress (
  id            uuid primary key default gen_random_uuid(),
  couple_id     uuid not null references couples(id) on delete cascade,
  campaign_id   uuid not null references campaigns(id) on delete cascade,
  current_chapter int not null default 1,
  status        text not null default 'active',
  started_at    timestamptz default now(),
  completed_at  timestamptz,
  constraint unique_couple_campaign unique (couple_id, campaign_id)
);

-- ── Campaign rewards (per chapter or campaign-wide) ──
create table public.campaign_rewards (
  id            uuid primary key default gen_random_uuid(),
  campaign_id   uuid not null references campaigns(id) on delete cascade,
  chapter_number int,
  reward_type   text not null,
  reward_data   jsonb not null default '{}'::jsonb,
  created_at    timestamptz default now()
);

-- ── Extend quests with campaign link (backward compatible) ──
alter table public.quests add column if not exists campaign_id uuid references campaigns(id) on delete set null;
alter table public.quests add column if not exists campaign_chapter int;

-- Indexes
create index idx_campaigns_active on campaigns(is_active) where is_active = true;
create index idx_chapters_campaign on campaign_chapters(campaign_id, chapter_number);
create index idx_progress_couple on couple_campaign_progress(couple_id);
create index idx_rewards_campaign on campaign_rewards(campaign_id);

-- RLS
alter table public.campaigns enable row level security;
alter table public.campaign_chapters enable row level security;
alter table public.couple_campaign_progress enable row level security;
alter table public.campaign_rewards enable row level security;

create policy "Authenticated users can read campaigns"
  on public.campaigns for select using (auth.role() = 'authenticated');

create policy "Authenticated users can read chapters"
  on public.campaign_chapters for select using (auth.role() = 'authenticated');

create policy "Authenticated users can read rewards"
  on public.campaign_rewards for select using (auth.role() = 'authenticated');

create policy "Users can read their campaign progress"
  on public.couple_campaign_progress for select using (
    couple_id in (select id from couples where user_a_id = auth.uid() or user_b_id = auth.uid())
  );

create policy "Users can start campaigns"
  on public.couple_campaign_progress for insert with check (
    couple_id in (select id from couples where user_a_id = auth.uid() or user_b_id = auth.uid())
  );

create policy "Users can update their campaign progress"
  on public.couple_campaign_progress for update using (
    couple_id in (select id from couples where user_a_id = auth.uid() or user_b_id = auth.uid())
  );

-- ── Seed: "The Love Heist" campaign ──
insert into public.campaigns (slug, title, subtitle, description, total_chapters, judge_persona, difficulty_curve, is_active, sort_order)
values (
  'the_love_heist',
  'The Love Heist',
  'Crack the vault together.',
  'A five-chapter adventure where you and your partner team up to pull off the ultimate heist — stealing each other''s hearts. Chaos Gremlin is your unpredictable handler.',
  5,
  'chaos_gremlin',
  'linear',
  true,
  1
);

-- Seed chapters for The Love Heist
insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 1,
  'The Invitation',
  'So... you two think you can pull off a heist? 💀 Interesting. Very interesting. I''ve been watching you, and honestly? You might just be chaotic enough to make this work. Welcome to The Love Heist. First task: prove you can work together without imploding.',
  'Not bad for rookies. You didn''t completely fall apart. Chapter 1 — done. But don''t get cocky. The real chaos starts now.',
  'curious and testing — you''re evaluating whether this couple has what it takes. Be playful but probing.',
  3, 1, 2
from public.campaigns c where c.slug = 'the_love_heist';

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 2,
  'The Training Montage',
  'Alright, time to level up. Every great heist team needs training. I''m going to push you — hard. Think of me as your chaotic drill sergeant. Ready? BRO, you better be ready.',
  'Okay okay okay. I''ll admit it — you two are getting good. The training montage is complete. But Chapter 3... Chapter 3 is where things get interesting. 💀',
  'encouraging but intense — you''re a drill sergeant who secretly believes in them. Push hard but celebrate wins.',
  3, 2, 3
from public.campaigns c where c.slug = 'the_love_heist';

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 3,
  'The Double Cross',
  'Listen. I need to tell you something. One of you... might be a double agent. I''m not saying who. I''m not saying it''s true. But I''m watching. Every. Single. Message. Trust no one. Especially each other. 💀💀💀',
  'Plot twist: the double agent was ME the whole time. Just kidding. Or am I? Chapter 3 survived. You two are either brave or completely unhinged. I respect it.',
  'paranoid and suspicious — question everything the seeker says. Drop hints about betrayal. Be dramatic and conspiratorial.',
  3, 3, 4
from public.campaigns c where c.slug = 'the_love_heist';

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 4,
  'The Heist',
  'This is it. The big one. Everything we''ve trained for comes down to this. The vault is RIGHT THERE. I can smell the romance inside. Are you ready to crack it open? Because I am HYPED. LET''S GO. 🔥💀🔥',
  'YOU DID IT. THE VAULT IS CRACKED. I''m literally shaking. That was the most beautiful heist I''ve ever witnessed. One more chapter. The getaway.',
  'excited and manic — you''re riding the adrenaline high. Everything is AMAZING and INTENSE. Use caps and fire emojis liberally.',
  3, 3, 5
from public.campaigns c where c.slug = 'the_love_heist';

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 5,
  'The Getaway',
  'We made it. The heist is done. Now we just need to get away clean. This is the victory lap, but don''t let your guard down — the best couples celebrate together. Show me what you''ve got one last time.',
  'And that''s a wrap on The Love Heist. 🏆 You two are officially legendary. I don''t say that lightly. Actually, I''ve never said it before. You earned it. Now go be disgustingly in love or whatever.',
  'relieved and celebratory — the mission is accomplished. Be warm, proud, and genuinely happy for them. This is the emotional payoff.',
  3, 4, 5
from public.campaigns c where c.slug = 'the_love_heist';

-- Seed campaign rewards
insert into public.campaign_rewards (campaign_id, chapter_number, reward_type, reward_data)
select c.id, null, 'xp_bonus', '{"xp": 500}'::jsonb
from public.campaigns c where c.slug = 'the_love_heist';

insert into public.campaign_rewards (campaign_id, chapter_number, reward_type, reward_data)
select c.id, null, 'collectible', '{"rarity": "legendary", "persona": "chaos_gremlin", "title": "Master Heist Operative"}'::jsonb
from public.campaigns c where c.slug = 'the_love_heist';
