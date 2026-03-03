# Winkidoo – Project state (session memory)

Short reference for what’s implemented and what’s next. No secrets or keys.

---

## Implemented (as of Mar 2026)

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

### Migrations (run in order)
- 001–008: schema, battle_messages, wink_plus, surprise type/photo, blueprint v1, resolved_at, creator_defense RPC, realtime.
- 009–010: user_push_tokens, multi-device.
- 011: judges data-driven (tagline, difficulty, chaos, tone_tags, preview_quotes, primary_color_hex, is_premium, season_start/end).
- 012: judges.is_new.
- 013: judges.season_push_sent.

---

## Next / optional

- Local run + LOCAL_VALIDATION checklist; Part 1 manual smoke-test (two accounts).
- Fix photo "Bucket not found" (ensure Storage bucket `surprises` exists and policies).
- Voice recording: device permissions and record package version if issues on Android.
- Push: filter tokens by updated_at last 90 days or users in a couple (scale).
- IAP/Stripe for Wink+ (wink_plus_until set by backend).

---

## Docs

- **README.md** – Setup, env (SUPABASE_URL, SUPABASE_ANON_KEY, GEMINI_API_KEY via --dart-define), structure, development log.
- **supabase/migrations/README.md** – Migration list and webhook steps.
- **docs/FIREBASE_AND_PUSH_SETUP.md** – Firebase project, configs, Edge Function deploy, secrets, webhooks (surprises + judges).
- **docs/STORAGE_SETUP.md** – Storage bucket and policies.
- **docs/OAUTH_AND_STORE_SETUP.md** – OAuth and store (no secrets in repo).
- **decision-log.md** – Architecture and product decisions.
