# Winkidoo – Project state (session memory)

Short reference for what’s implemented and what’s next. No secrets or keys.

---

## Implemented (as of Mar 2026)

### March 4, 2026 – Home/Vault/Footer redesign + avatar profiles + visual parity pass
- **Top bar parity:** `WinkidooTopBar` adds `matchLogoToWordmark` so logo scales to wordmark presence on Home/Vault.
- **Vault UX cleanup polish:** Featured chest copy is now a single-line sentence ("Open your next surprise when it feels right.") and no longer overlaps icon lock treatment.
- **Persona/gender overlays (Vault):**
  - New deterministic resolver `resolvePersonaAssetPath({personaId, userGender})` in `judge_asset_map.dart`.
  - Vault hero/chest now resolve overlays from surprise personas + profile gender and force distinct overlays for top-zone cards.
- **Footer/nav redesign (global shell):**
  - `WinkBottomNav` now has style and icon abstractions (`WinkBottomNavStyle`, `WinkNavIconSet`).
  - New color direction: blue-charcoal base + solid amber center Battle CTA (non-gradient).
  - Switched to `phosphor_flutter` icons for unique visual identity.
- **Profile avatar system (new users + existing users):**
  - New constants/service/providers:
    - `core/constants/avatar_presets.dart`
    - `services/profile_avatar_service.dart`
    - `userAvatarProfileProvider`, `effectiveProfileAvatarProvider`
  - Avatar selection available in both profile completion sheet and profile editor:
    - upload from device gallery
    - select from Wink avatar preset assets
  - Profile header now renders uploaded URL or preset asset fallback.
- **Supabase data/storage update:**
  - Added migration `010_profiles_avatar.sql`:
    - `public.profiles` (avatar_mode, avatar_asset_path, avatar_storage_path, avatar_url, timestamps)
    - RLS policies (own row select/insert/update)
    - `updated_at` trigger
    - storage bucket and policies for `profile-avatars`.
- **Visual parity extension:** Winks and Profile pages now use Home/Vault background glow language and card surfaces.

### March 3, 2026 – Premium auth refresh + Home realignment + profile gating + judge assets
- **Welcome/Get Started screen:** `WelcomeAuthScreen` updated to premium hero style with full background image (`assets/images/background .png`), headline/subheadline, and single CTA `Get Started` routed to `/login`; removed unwanted blur and refined spacing/alignment.
- **Auth screen redesign (`/login`):** Minimal premium signup/login mode on one screen with updated logo treatment (`winkidoo new logo.png`), polished inputs/buttons, show/hide password, forgot password on login mode, and social stack for Google/Apple/Facebook using local PNG assets.
- **Top bar update (mock-aligned):** `WinkidooTopBar` now supports and displays `logo + Winkidoo + bell badge + fire streak badge`; new prop `streakCount` added and wired from `streakProvider.currentStreak`.
- **Home composition refresh:** Home keeps purple background but now uses modular minimal cards and better hierarchy. Orbit section now includes horizontal avatar rail inside the hero strip with helper text "Tap an avatar to challenge!" and battle-start tap routing.
- **Overflow mitigation:** Home card internals adjusted toward flexible sizing/compact spacing behavior to reduce small-device overflows while preserving touch targets.
- **Profile completeness gate (new):**
  - New provider file `lib/providers/user_profile_provider.dart` exposes `userProfileMetaProvider`, `isProfileCompleteProvider`, and `missingProfileFieldsProvider`.
  - New reusable modal `lib/core/widgets/profile_completion_sheet.dart` collects and saves `name`, `age`, `gender` to **Supabase auth user metadata**.
  - Gate wired before create/join battle flows (Home and Vault entry paths), and profile screen now has editable "Game Profile" section.
- **Judge asset resolver (new):**
  - `lib/core/constants/judge_asset_map.dart` centralizes persona-to-asset mapping using uploaded judge files.
  - Rule implemented: opposite-gender default; if gender is `na`, select random variant per app session.
  - Applied across judge surfaces (selection, tease, spotlight, archive/detail/profile cards) with fallback order: mapped asset -> existing avatar path -> placeholder.
- **Navigation/back behavior polish:** Prior pass completed pop-first/fallback behavior and root Android double-back exit handling.
- **Asset migration:** Old logo/background/social image files were replaced by new user-provided assets in `assets/images/`.

### Auth & couple
- Email + OAuth (Google, Apple, Facebook) via Supabase; deep links for mobile callback.
- Couple create/join; Vault Sealed screen when creator waits for partner; redirect to vault when linked.
- Welcome screen; link-vault UI; onboarding (3 screens) and empty vault state.

### Vault & create
- Vault list (Waiting for You / Your Surprises); realtime subscription.
- Create surprise: judge selection 2.0 (full-screen aura, portrait, difficulty/chaos, tone tags, rotating quotes, vault sealing transition); type text/photo/voice; unlock method; difficulty; auto-delete; Lock it.
- Data-driven judges: DB table `judges` (migrations 011–013); activeJudgesProvider, judgeByPersonaIdProvider; seasonal and "New" badges; premium gating via is_premium.
- **UI refresh (Home + Vault, mobile-first):**
  - New shared UI primitives in `lib/core/widgets/`: `WinkCard`, `PillCta`, `AvatarChipRow`, `WinkidooTopBar`, `WinkBottomNav`.
  - Theme token expansion in `app_theme.dart` for light pastel brand layer + component tokens (`topBarBg`, `cardGradientA/B`, `pillBg`, `pillBorder`, `navBg`, `navActive`, `navInactive`, `badgeBg`) with dark-mode fallbacks.
  - Home redesigned to mockup-aligned structure: branded top bar, avatar rail, battle hero, vault summary, judge spotlight, and recent wins.
  - Vault redesigned to mockup-aligned structure: branded header, linked-vault hero, search/actions strip, chest callout, and refreshed list cards.
  - Router shell bottom navigation replaced with branded custom nav and highlighted center camera action (`/shell/create`), while preserving route contracts.

### Battle & reveal
- Submission → battle chat (AI judge, persuasion meter, creator defense); realtime surprise row for auto-navigate on resolve.
- Pre-battle tease (judge aura, portrait, lock pulse, quote, "Begin Persuasion"; 1.5s auto-advance or tap).
- Reveal (decrypt content, confetti on unlock); photo/voice via Storage signed URLs.
- Hint (5 Winks) and instant unlock (50 Winks).

### Treasure & profile
- Treasure archive 2.0: overview cards (judge, outcome, date, meter, attempts); blur + lock for non–Wink+; tap → detail. Detail: free = summary + "Unlock full memory with Wink+"; Wink+ = full content + chat replay + Replay Battle. replay_battle_view = sequential message + meter replay.
- Profile: relationship stats; "Your Dynamic" (couple stats + monthly bar chart); Achievements (horizontal badges, tap → sheet); achievement unlock celebration (modal once per achievement, seen IDs in shared_preferences); subscription card; settings; logout.
- Couple stats: totalBattles, unlockRate, toughestJudge, avgPersuasion, creatorDefenseRatio, monthlyBattles (from resolved surprises only).

### Achievements & season
- Achievements: computed from stats/surprises (no DB); First Victory, 5/10 Battles, 100+ Persuasion, Beat Chaos Gremlin, 3+ Creator Defenses, Active 3 Months. Celebration modal on first unseen unlock (Home and Profile); storage service for seen IDs.
- Season recap: provider returns most recently ended seasonal judge recap; Home shows SeasonRecapScreen when recap != null and !hasSeenSeason (storage service); onFinish marks seen and pops; onReplayHighlight → treasure-archive/:id. Celebration order on Home: recap first, then achievement modal (single guard).

### Push & Edge Function
- user_push_tokens (009, 010 multi-device); push_service upserts token on login and onTokenRefresh.
- Edge Function send_battle_notification: surprises (INSERT/UPDATE) → battle notifications; judges (INSERT/UPDATE) → "✨ A New Judge Has Arrived" when seasonal + is_new + !season_push_sent, then set season_push_sent = true.
- Deep links: surprise_id → battle or reveal; type season_launch → /shell/create.
- Firebase: Android (google-services.json), iOS (GoogleService-Info.plist), Web (index.html); FIREBASE_SERVICE_ACCOUNT in Supabase secrets only.

### Phase 1 — Core USP + Daily Hooks ✅
- Love Quests: `quests` table, quest create/progress/complete screens, AI judge quest context injection
- Daily Streaks: `daily_activity_log`, fire emoji escalation (1→7→30→100+ days)
- Time Capsule Vault: `unlock_after` on surprises, date picker, countdown UI
- Battle Highlights: share card image via `RepaintBoundary` + `share_plus`

### Phase 2 — Gaming + Social Depth ✅
- Love Levels XP: `couple_xp` table, `XpService`, level badge in top bar + profile XP bar
- Judge Memory: `judge_memory` table, post-battle Gemini summary, injected into system prompt
- Dynamic Judge Moods: time-of-day/weekday context in judge system prompt
- Partner Peek: Supabase Realtime Presence — "✏️ Your partner is crafting..." banner

### Phase 3 — Viral Growth ✅
- Battle Pass: `battle_pass_seasons` + `battle_pass_progress`, Bronze/Silver/Gold tiers, points on create/win/quest
- Couple Referral System: invite link deep link, +50 Winks reward UI
- Collaborative Vault: both partners add encrypted pieces, revealed side-by-side on win

### Phase 4 — Aspirational ✅
- Judge Collectible Cards: `judge_collectibles` table, rarity (common/rare/legendary), collection grid in Profile
- Couple Leaderboard: anonymous global ranking by XP, top 50, "You" highlight
- Relationship Timeline: milestone map from existing surprise history (no new DB)
- Home Screen Widget: iOS WidgetKit + Android App Widget — streak, pending surprises, daily prompt
  - iOS: `WinkidooWidgetExtension` target in Xcode; App Group `group.com.winkidoo.app` added to both Runner and WinkidooWidgetExtension targets; entitlements wired; deployment target iOS 16; pending physical-device test
  - Android: `WinkidooWidgetProvider.kt`, layout + info XML, registered in `AndroidManifest.xml`
  - Flutter bridge: `lib/services/widget_service.dart` via `home_widget ^0.7.0`; called from `VaultListScreen` and `RevealScreen`

### Migrations (run in order)
- 001–008: schema, battle_messages, wink_plus, surprise type/photo, blueprint v1, resolved_at, creator_defense RPC, realtime.
- 009–010: user_push_tokens, multi-device.
- 010: profiles avatar persistence + profile-avatars storage policies.
- 011–013: judges data-driven, is_new, season_push_sent.
- 014: quests + time capsule (quest_id, quest_step, unlock_after on surprises).
- 015: daily_activity_log.
- 016: couple_xp (Love Levels).
- 017: judge_memory.
- 018: battle_pass_seasons + battle_pass_progress.
- 019: referrals.
- 020: collaborative vault columns on surprises.
- 021: judge_collectibles.
- 022: public leaderboard read policy on couple_xp.
- 023: daily_dares (Daily Love Dares).
- 024: judge_packs + judge_pack_judges + pack_dare_templates + couple_active_pack (Themed Battle Packs).
- 025: mini_game_types + daily_mini_games + pack_mini_game_templates (Couple Mini-Games).
- 026: campaigns + campaign_chapters + couple_campaign_progress + campaign_rewards (Story Mode).
- 027: content expansion — 3 new campaigns + 3 themed packs seed data.
- 028: custom_judges + custom_judge_uses (Custom AI Judge Creator + Marketplace).
- 029: custom_judges status + notification_text columns (web search + async generation).
- 030: custom_judges is_active_for_battle column (battlefield toggle).

### March 29, 2026 — Major feature expansion
- **Daily Love Dares**: AI daily challenges, photo/voice responses, shareable dare cards, realtime partner notifications
- **Phase 5 — Themed Battle Packs**: judge_packs system with persona overrides, themed dares, BP multiplier. 4 packs: Valentine Vibes, Horror Night, Bollywood Romance, Summer Fling
- **Phase 6 — Couple Mini-Games**: 4 rotating daily games (Would You Rather, Love Trivia, Caption This, Finish My Sentence) with AI grading
- **Phase 7 — Story Mode Campaigns**: narrative quest chains with persona_mood_override (judge personality shifts per chapter). 4 campaigns: The Love Heist, Romance Academy, Operation Date Night, The Ex Files
- **Visual Polish**: stagger card entrance animations, confetti on all completions, shimmer skeleton loaders, Couple Wrapped shareable stats card
- **Custom AI Judge Creator**: web search via Tavily API (free tier 1,000/month), multi-mood selection (funny+savage+chill), 8-dimension personality analysis framework, community marketplace, judge audition chat, gallery photo upload, publish/private/share flow
- **My Judges Management**: battlefield toggle (only active judges appear in carousel), publish/unpublish, change avatar, delete (blocked for published), signed URL avatar display
- **Rate Limiting**: 3 custom judges/day per couple (bypassed in debug mode), Gemini spend cap guidance
- **Environment**: Added TAVILY_API_KEY via --dart-define

---

## Next / optional

- **Known bugs to fix**: judge delete from My Judges, avatar photo display consistency, marketplace published judges visibility
- IAP/Stripe for Wink+ (RevenueCat — wink_plus_until set by backend).
- Push notifications for dares, mini-games, campaign chapters, custom judge ready.
- Onboarding polish (guided first experience, welcome gift, first surprise prompt).
- AI Love Coach (opt-in relationship insights from surprise patterns).

---

## Docs

- **README.md** – Setup, env (SUPABASE_URL, SUPABASE_ANON_KEY, GEMINI_API_KEY via --dart-define), structure, development log.
- **supabase/migrations/README.md** – Migration list and webhook steps.
- **docs/FIREBASE_AND_PUSH_SETUP.md** – Firebase project, configs, Edge Function deploy, secrets, webhooks (surprises + judges).
- **docs/STORAGE_SETUP.md** – Storage bucket and policies.
- **docs/OAUTH_AND_STORE_SETUP.md** – OAuth and store (no secrets in repo).
- **decision-log.md** – Architecture and product decisions.
