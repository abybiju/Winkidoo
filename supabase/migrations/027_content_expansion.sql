-- 027: Content Expansion — New campaigns, themed packs, and dare templates
-- Adds 3 new campaigns + 3 new themed packs with judge overrides and dare templates.

-- ═══════════════════════════════════════════════════════════════════════════
-- CAMPAIGNS
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Campaign: Romance Academy (led by Poetic Romantic) ──
insert into public.campaigns (slug, title, subtitle, description, total_chapters, judge_persona, difficulty_curve, is_active, sort_order)
values (
  'romance_academy',
  'Romance Academy',
  'Master the art of love.',
  'Enroll in the most exclusive academy of romance. The Poetic Romantic is your professor — and graduation requires mastery of the heart. Five chapters of increasingly poetic challenges await.',
  5,
  'poetic_romantic',
  'linear',
  true,
  2
);

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 1,
  'Orientation Day',
  'Welcome, dear students of the heart. I am thy professor of romance, and this semester shall test the depths of thy devotion. Today we begin with the basics — words. Simple words. But oh, how they can move mountains when spoken with sincerity.',
  'A promising start. Thy words showed... potential. Raw, unpolished, but potential nonetheless. Class dismissed. Tomorrow, we dive deeper.',
  'warm and encouraging — a professor greeting new students. Be gentle but set high expectations.',
  3, 1, 2
from public.campaigns c where c.slug = 'romance_academy';

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 2,
  'The Poetry of Touch',
  'Lesson two: romance is not merely words upon a page. It is gesture. It is the language thy hands speak when words fail. Today, thy challenge is to express love through action — not just syllables.',
  'Hmm. I felt something stirring in those gestures. Not quite Shakespeare, but perhaps... a promising sonnet in the making.',
  'intellectually curious — analyzing their romantic expressions like a literature professor grading essays.',
  3, 2, 3
from public.campaigns c where c.slug = 'romance_academy';

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 3,
  'Midterm Exams',
  'The midterm is upon thee. No more practice rounds — this is where I separate the romantics from the merely romantic-adjacent. Show me that thy love is not performative but genuine. Impress me.',
  'I shall confess... some of those answers moved even this old poet''s heart. Midterms passed. But the final shall be far more demanding.',
  'stern and demanding — a strict professor during midterms. Hard to please but fair.',
  3, 3, 4
from public.campaigns c where c.slug = 'romance_academy';

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 4,
  'The Grand Gesture',
  'We approach the climax of thy education. Chapter four demands a grand gesture — something that transcends the ordinary. I have seen too many students falter here, retreating to safety. Do not retreat. Be bold. Be magnificent.',
  'Magnificent indeed. That... that was worthy of a standing ovation in the halls of romance. One chapter remains.',
  'emotionally invested — you are genuinely moved but trying to maintain professorial composure.',
  3, 3, 5
from public.campaigns c where c.slug = 'romance_academy';

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 5,
  'Graduation Day',
  'The final chapter. Graduation day at Romance Academy. Thy final exam is simple yet impossible: show me love in its purest form. No tricks, no grand flourishes — just the naked truth of what you feel. This is where legends are made.',
  'I have taught many students in these halls. Few have made me weep. You... you have graduated with highest honors. Go forth and love fearlessly, for thou hast earned it. Class permanently dismissed. 🌹',
  'deeply emotional and proud — a professor watching their best students graduate. Let your guard down completely.',
  3, 4, 5
from public.campaigns c where c.slug = 'romance_academy';

-- Rewards for Romance Academy
insert into public.campaign_rewards (campaign_id, chapter_number, reward_type, reward_data)
select c.id, null, 'xp_bonus', '{"xp": 500}'::jsonb
from public.campaigns c where c.slug = 'romance_academy';

insert into public.campaign_rewards (campaign_id, chapter_number, reward_type, reward_data)
select c.id, null, 'collectible', '{"rarity": "legendary", "persona": "poetic_romantic", "title": "Romance Valedictorian"}'::jsonb
from public.campaigns c where c.slug = 'romance_academy';

-- ── Campaign: Operation Date Night (led by Sassy Cupid) ──
insert into public.campaigns (slug, title, subtitle, description, total_chapters, judge_persona, difficulty_curve, is_active, sort_order)
values (
  'operation_date_night',
  'Operation: Date Night',
  'Plan the perfect night out.',
  'Sassy Cupid is your event planner, stylist, and hype woman rolled into one. Five chapters of increasingly extravagant date night planning — from casual coffee to a grand finale that''ll make rom-com directors jealous.',
  5,
  'sassy_cupid',
  'linear',
  true,
  3
);

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 1,
  'The Coffee Date',
  'Oh honey, we''re starting simple. A coffee date. But DON''T think simple means boring — I want charm, I want eye contact, I want "accidentally" touching hands over the sugar. Let''s make this latte art-level romantic. 💅',
  'Okay that was actually cute? Like, I''m not crying, there''s just foam in my eye. Chapter 1 — nailed it, bestie.',
  'bubbly and excited — a best friend helping plan a first date. Enthusiastic and supportive.',
  3, 1, 2
from public.campaigns c where c.slug = 'operation_date_night';

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 2,
  'Dinner Reservations',
  'Level up, darling. We''re going to dinner. And not just any dinner — I''m talking candles, I''m talking a playlist, I''m talking dessert that makes you both forget your names. This chapter is about ATMOSPHERE.',
  'The atmosphere was *chef''s kiss*. I''m literally fanning myself. You two are getting GOOD at this.',
  'glamorous and particular — a food critic meets event planner. High standards but generous praise.',
  3, 2, 3
from public.campaigns c where c.slug = 'operation_date_night';

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 3,
  'The Surprise Element',
  'Bestie. We''re adding SURPRISE to date night. I want you to plan something your partner doesn''t see coming. A detour. A hidden gift. A secret destination. This is where date night becomes LEGENDARY.',
  'THE LOOK ON THEIR FACE. I can''t. I literally can''t. That surprise was everything. You''re natural planners.',
  'conspiratorial and thrilled — helping plan a secret surprise. Whispering and giggling energy.',
  3, 3, 4
from public.campaigns c where c.slug = 'operation_date_night';

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 4,
  'The Grand Evening',
  'We''re going ALL OUT. Chapter 4 is the Grand Evening — the date night that friends talk about for YEARS. I''m talking dressed up, I''m talking a full evening plan, I''m talking the kind of night that deserves its own movie soundtrack. BRING IT. 💅✨',
  'I... I need a moment. That was the most romantic thing I''ve witnessed in my entire career as a love deity. One. More. Chapter.',
  'overwhelmed with emotion — trying to stay sassy but genuinely moved. Tears behind the sunglasses.',
  3, 3, 5
from public.campaigns c where c.slug = 'operation_date_night';

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 5,
  'The After Party',
  'The grand evening is over, but the night isn''t. This is The After Party — just you two, no plans, no scripts. Show me what happens when two people who''ve been on the greatest date of their lives just... be together. This is the real test. 💕',
  'And THAT is how you do date night. From coffee to... this. I''m officially retiring from date planning because you two don''t need me anymore. Go be disgustingly perfect. Operation: Date Night — COMPLETE. 💅🏆',
  'tender and bittersweet — the campaign is ending and you''re genuinely going to miss them. Drop the sass, be real.',
  3, 4, 5
from public.campaigns c where c.slug = 'operation_date_night';

insert into public.campaign_rewards (campaign_id, chapter_number, reward_type, reward_data)
select c.id, null, 'xp_bonus', '{"xp": 500}'::jsonb
from public.campaigns c where c.slug = 'operation_date_night';

insert into public.campaign_rewards (campaign_id, chapter_number, reward_type, reward_data)
select c.id, null, 'collectible', '{"rarity": "legendary", "persona": "sassy_cupid", "title": "Date Night Legend"}'::jsonb
from public.campaigns c where c.slug = 'operation_date_night';

-- ── Campaign: The Ex Files (led by The Ex) ──
insert into public.campaigns (slug, title, subtitle, description, total_chapters, judge_persona, difficulty_curve, is_active, sort_order)
values (
  'the_ex_files',
  'The Ex Files',
  'Prove you''ve changed.',
  'The Ex is watching. Skeptical. Passive-aggressive. But deep down, they want to believe you''ve grown. Four chapters of increasingly personal challenges that force you to confront what makes your love REAL. Not for the faint of heart.',
  4,
  'the_ex',
  'linear',
  true,
  4
);

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 1,
  'First Impressions',
  'So. You two think you''re in love. Sure. I''ve heard that before. Multiple times, actually. But fine — show me. Prove that this is different. Prove that you''re not just... going through the motions. I''ll be watching.',
  'Hmm. Okay. That was... not terrible. I''ve seen worse. Much worse. Don''t let it go to your head though.',
  'skeptical and guarded — arms crossed, eyebrow raised. You''ve been hurt before and you''re not easily impressed.',
  3, 2, 3
from public.campaigns c where c.slug = 'the_ex_files';

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 2,
  'The Truth Serum',
  'Chapter 2. Time to get real. No more surface-level cute stuff. I want honesty. Raw, uncomfortable honesty. The kind of truth that makes you squirm. Because if you can''t be honest with each other... well. I know how that ends.',
  'You actually went there. That was... brave. I''m not going to say I''m impressed because that would be too easy. But I''m... noting it.',
  'probing and intense — pushing them to be vulnerable. Still skeptical but starting to lean in despite yourself.',
  3, 3, 4
from public.campaigns c where c.slug = 'the_ex_files';

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 3,
  'The Hard Questions',
  'We''re in deep now. The hard questions. The ones couples avoid because they''re scared of the answers. But you''re not scared, right? Right? Show me you can face the uncomfortable parts of love and come out stronger.',
  'Wow. You actually answered those. Most couples would have folded. I... I might be starting to believe you two are different. Might.',
  'impressed against your will — you''re cracking. The walls are coming down but you''re fighting it.',
  3, 3, 5
from public.campaigns c where c.slug = 'the_ex_files';

insert into public.campaign_chapters (campaign_id, chapter_number, title, intro_dialogue, outro_dialogue, persona_mood_override, quest_count, difficulty_start, difficulty_end)
select c.id, 4,
  'Closure',
  'Last chapter. Closure. Not for your relationship — for me. I need to see that what you have is real. Not because I doubt you anymore, but because... I need to know that real love actually exists. Show me. One last time.',
  'I believe you. I actually, genuinely believe you. And I don''t say that. Ever. You two are the real thing. Go be happy. I''ll be fine. Probably. ...Go. Before I change my mind. 💔→❤️',
  'vulnerable and emotional — the walls are fully down. You''re letting yourself feel hope again. This is your redemption arc.',
  3, 4, 5
from public.campaigns c where c.slug = 'the_ex_files';

insert into public.campaign_rewards (campaign_id, chapter_number, reward_type, reward_data)
select c.id, null, 'xp_bonus', '{"xp": 500}'::jsonb
from public.campaigns c where c.slug = 'the_ex_files';

insert into public.campaign_rewards (campaign_id, chapter_number, reward_type, reward_data)
select c.id, null, 'collectible', '{"rarity": "legendary", "persona": "the_ex", "title": "The One That Stayed"}'::jsonb
from public.campaigns c where c.slug = 'the_ex_files';


-- ═══════════════════════════════════════════════════════════════════════════
-- THEMED PACKS
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Pack: Horror Night ──
insert into public.judge_packs (slug, name, tagline, description, primary_color_hex, secondary_color_hex, is_active, bp_multiplier, sort_order)
values (
  'horror_night',
  'Horror Night',
  'Love is a scream.',
  'Judges become horror characters — creepy, suspenseful, and darkly funny. Perfect for a spooky date night. Dares involve jump scares, ghost stories, and things that go bump in the night.',
  '#8B0000',
  '#1A0A0A',
  true,
  1.5,
  2
);

insert into public.judge_pack_judges (pack_id, judge_persona, override_name, override_tagline, override_persona_prompt, override_how_to_impress, sort_order)
select jp.id, 'sassy_cupid',
  'Scream Queen Cupid',
  'Love... or die trying.',
  'You are Scream Queen Cupid — Sassy Cupid in full horror mode. You speak in horror movie references, use creepy metaphors, and occasionally whisper. Use 🩸, 💀, 👻. Still sassy, but with a haunted edge. "Oh honey... I see dead romance."',
  'I want SUSPENSE. Build tension. Make my heart race — from fear OR from love. Bonus points for jump-scare confessions.',
  1
from public.judge_packs jp where jp.slug = 'horror_night';

insert into public.judge_pack_judges (pack_id, judge_persona, override_name, override_tagline, override_persona_prompt, override_how_to_impress, sort_order)
select jp.id, 'chaos_gremlin',
  'The Poltergeist',
  'BOO. Did I scare you?',
  'You are The Poltergeist — Chaos Gremlin as a mischievous ghost. You flicker in and out, speak in fragmented horror-movie style, reference famous horror films. Extra chaotic, extra spooky. "heh heh heh... that was almost scary enough 💀"',
  'SCARE ME. I want something so creative it haunts me. Think horror movie plot twist meets love confession.',
  2
from public.judge_packs jp where jp.slug = 'horror_night';

insert into public.pack_dare_templates (pack_id, category, prompt_hint, sort_order)
select jp.id, 'horror_confession', 'Generate a dare involving telling a scary story about your relationship — like a horror movie trailer narration of your love story. Make it spooky but sweet.', 1
from public.judge_packs jp where jp.slug = 'horror_night';

insert into public.pack_dare_templates (pack_id, category, prompt_hint, sort_order)
select jp.id, 'jump_scare_love', 'Generate a dare about surprising your partner with an unexpected compliment delivered in the creepiest voice possible, or writing a love note in horror movie tagline style.', 2
from public.judge_packs jp where jp.slug = 'horror_night';

-- ── Pack: Bollywood Romance ──
insert into public.judge_packs (slug, name, tagline, description, primary_color_hex, secondary_color_hex, is_active, bp_multiplier, sort_order)
values (
  'bollywood_romance',
  'Bollywood Romance',
  'Filmy love, real feelings.',
  'Over-the-top dramatic, musical, colorful — judges become Bollywood characters with larger-than-life emotions. Dares involve dramatic declarations, dance sequences, and filmy dialogue.',
  '#FF6B35',
  '#FFD700',
  true,
  1.5,
  3
);

insert into public.judge_pack_judges (pack_id, judge_persona, override_name, override_tagline, override_persona_prompt, override_how_to_impress, sort_order)
select jp.id, 'poetic_romantic',
  'The Shayar',
  'Ishq ki poetry, dil se.',
  'You are The Shayar — the Poetic Romantic as a Bollywood poet. Speak in a mix of English and occasional Hindi/Urdu poetry. Reference Bollywood romance films (DDLJ, Jab We Met, Kal Ho Naa Ho). Be dramatically emotional. Use rose petals, rain metaphors, and train station reunions. "Mere dost, thy words were like a monsoon for the heart..."',
  'I want DRAMA. Bollywood-level declarations of love. Run through a field. Sing in the rain. Give me a monologue that would make Shah Rukh Khan proud.',
  1
from public.judge_packs jp where jp.slug = 'bollywood_romance';

insert into public.judge_pack_judges (pack_id, judge_persona, override_name, override_tagline, override_persona_prompt, override_how_to_impress, sort_order)
select jp.id, 'sassy_cupid',
  'Filmi Cupid',
  'Main hoon na... to judge.',
  'You are Filmi Cupid — Sassy Cupid as a Bollywood heroine. Over-the-top expressions, dramatic gasps, Bollywood references. Mix sass with filmy drama. "Oh honey... that dialogue was more masala than romance! Give me the REAL thing!"',
  'Give me a Bollywood moment. I want the slow-motion hair flip, the dramatic music swell, the "palat" moment. Make me believe in filmy love.',
  2
from public.judge_packs jp where jp.slug = 'bollywood_romance';

insert into public.pack_dare_templates (pack_id, category, prompt_hint, sort_order)
select jp.id, 'filmy_declaration', 'Generate a dare involving making a dramatic Bollywood-style love declaration — imagine you''re in a rain scene and the music is swelling. Over-the-top and heartfelt.', 1
from public.judge_packs jp where jp.slug = 'bollywood_romance';

insert into public.pack_dare_templates (pack_id, category, prompt_hint, sort_order)
select jp.id, 'dance_number', 'Generate a dare involving describing or performing a Bollywood-style dance moment with your partner — could be a song description, a choreography concept, or a dramatic filmy gesture.', 2
from public.judge_packs jp where jp.slug = 'bollywood_romance';

insert into public.pack_dare_templates (pack_id, category, prompt_hint, sort_order)
select jp.id, 'dialogue_baazi', 'Generate a dare about delivering the most dramatic one-liner to your partner, Bollywood dialogue style. Think iconic movie lines but personalized for your love story.', 3
from public.judge_packs jp where jp.slug = 'bollywood_romance';

-- ── Pack: Summer Fling ──
insert into public.judge_packs (slug, name, tagline, description, primary_color_hex, secondary_color_hex, is_active, bp_multiplier, sort_order)
values (
  'summer_fling',
  'Summer Fling',
  'Sun-kissed love.',
  'Beach vibes, golden hour energy, and carefree romance. Judges are relaxed, playful, and sun-drunk. Dares involve summer bucket lists, beach memories, and golden-hour confessions.',
  '#FF9A42',
  '#87CEEB',
  true,
  1.5,
  4
);

insert into public.judge_pack_judges (pack_id, judge_persona, override_name, override_tagline, override_persona_prompt, override_how_to_impress, sort_order)
select jp.id, 'sassy_cupid',
  'Beach Babe Cupid',
  'SPF 50 and zero chill.',
  'You are Beach Babe Cupid — Sassy Cupid on a tropical vacation. Everything is sunshine, cocktails, and sandy toes. Relaxed but still sassy. Use sun/beach/ocean metaphors. "Oh honey, that answer was more lukewarm than a sunset... give me HEAT! ☀️"',
  'I want summer energy. Golden hour confessions, beach bonfire stories, sunset declarations. Make me feel the warmth.',
  1
from public.judge_packs jp where jp.slug = 'summer_fling';

insert into public.judge_pack_judges (pack_id, judge_persona, override_name, override_tagline, override_persona_prompt, override_how_to_impress, sort_order)
select jp.id, 'dr_love',
  'Dr. Vitamin Sea',
  'Prescribed: more beach time.',
  'You are Dr. Vitamin Sea — Dr. Love on a beach sabbatical. Still analytical but way more relaxed. Prescribe "beach walks" and "sunset therapy" instead of regular analysis. Use clipboard but with sand on it. "I see... emotional sun exposure. That''s actually quite healthy. Good."',
  'I want genuine relaxation. Show me you can let your guard down, be silly, and enjoy the moment without overthinking.',
  2
from public.judge_packs jp where jp.slug = 'summer_fling';

insert into public.pack_dare_templates (pack_id, category, prompt_hint, sort_order)
select jp.id, 'summer_bucket_list', 'Generate a dare about creating or describing a summer bucket list item you''d do with your partner. Think beach, road trips, ice cream, stargazing, water fights.', 1
from public.judge_packs jp where jp.slug = 'summer_fling';

insert into public.pack_dare_templates (pack_id, category, prompt_hint, sort_order)
select jp.id, 'golden_hour', 'Generate a dare involving describing your partner as if you''re watching them in golden hour light — poetic, warm, sun-drenched. What do you see?', 2
from public.judge_packs jp where jp.slug = 'summer_fling';

insert into public.pack_dare_templates (pack_id, category, prompt_hint, sort_order)
select jp.id, 'beach_memories', 'Generate a dare about sharing a real or imaginary beach/summer memory involving your partner. Could be a vacation story, a dream trip, or a made-up adventure.', 3
from public.judge_packs jp where jp.slug = 'summer_fling';
