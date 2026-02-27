# Winkidoo

**AI-powered Digital Surprise Vault for couples.** One person hides a message, photo, or voice note. Both can play: convince the AI judge to unlock it. Winner gets the reveal.

- **Stack:** Flutter 3.22+, Supabase (Auth, Realtime, Postgres, Storage), Riverpod 2.x, Google Gemini Flash (AI Judge).
- **Vibe:** Dual theme (Midnight Romance + Blush & Wink), 5 judge personas, text/photo/voice surprises, persuasion or collaboration unlock, Winks virtual economy.

**Product & UX (Blueprint v1)** — See **[PRODUCT_BLUEPRINT.md](PRODUCT_BLUEPRINT.md)** for the source of truth. In short: one shared vault per couple with sections **Waiting for You** (partner’s surprises) and **Your Surprises** (yours). One battle per surprise; base difficulty Easy 80, Medium 100, Hard 130; Dynamic Resistance Score; creator can defend; emotional states (Cold → Unlock). After battle: **Result Summary** then **Keep in Treasure** or **Delete Forever**. **Treasure Archive** holds metadata for kept battles; Wink+ can reopen revealed content. Winks for hints/instant unlock; Wink+ for more attempts, all judges, archive access.

---

## Next session: run locally + validate

**Left for next time:** local run + validation. When you sit to work next, run the app locally and use **[LOCAL_VALIDATION.md](LOCAL_VALIDATION.md)** to:

1. Confirm error screens (vault, battle chat), semantics (submission, send, create surprise), and loading skeletons.
2. Spot-check judge tone (witty/warm, playful roasts).
3. Then do the **Part 1 manual smoke-test** (two accounts, full flow) — see checklist in that file.

After that, MVP1 is shippable; consider Phase 2 (push notifications or shareable reveal cards).

---

## Setup

1. **Flutter**
   - Install [Flutter 3.22+](https://flutter.dev).
   - If `android/` and `ios/` are missing, run: `flutter create . --org com.winkidoo --project-name winkidoo`.
   - Run `flutter pub get`.

2. **Supabase**
   - Create a project at [supabase.com](https://supabase.com).
   - Run migrations **in order** (001 → 005) in the SQL Editor. See **[supabase/migrations/README.md](supabase/migrations/README.md)** for the list; run each file’s contents in sequence so `surprises` and related tables exist before Blueprint v1 (005).
   - Enable Email auth (or add other providers in Auth settings).
   - In Dashboard → Project Settings → API: copy **Project URL** and **anon public** key.

3. **Environment**
   - Create `.env` or use `--dart-define` for:
     - `SUPABASE_URL` = your Supabase project URL
     - `SUPABASE_ANON_KEY` = your Supabase anon key
     - `GEMINI_API_KEY` = your Google AI (Gemini) API key
   - Example run:
     ```bash
     flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=GEMINI_API_KEY=...
     ```

4. **Storage (for photo/voice surprises)**
   - Create a Storage bucket named **`surprises`** in Supabase Dashboard → Storage, and add policies so authenticated users can upload and read. See **[docs/STORAGE_SETUP.md](docs/STORAGE_SETUP.md)**.

5. **Realtime (optional)**
   - In Supabase Dashboard → Database → Replication, add `surprises` table to the publication so new surprises push to the app.

6. **Push notifications (optional)**
   - Firebase: **web** config is in **web/index.html** (Firebase SDK + `firebaseConfig`). For Android and iOS, each developer downloads **google-services.json** and **GoogleService-Info.plist** from Firebase Console (Winkidoo project) and places them in **android/app/** and **ios/Runner/** respectively; these paths are in `.gitignore`. Do not commit the Firebase service account key (set via `supabase secrets set FIREBASE_SERVICE_ACCOUNT=...`).
   - Run migrations **009** and **010** for push tokens (multi-device). Deploy Edge Function `send_battle_notification` and create Database Webhooks on `surprises` and `judges` (INSERT + UPDATE); see **[supabase/migrations/README.md](supabase/migrations/README.md)**. Full checklist: **[docs/FIREBASE_AND_PUSH_SETUP.md](docs/FIREBASE_AND_PUSH_SETUP.md)**.

7. **OAuth (Google / Apple / Facebook) and store setup**
   - Step-by-step without storing secrets in the repo: **[docs/OAUTH_AND_STORE_SETUP.md](docs/OAUTH_AND_STORE_SETUP.md)**. Covers Supabase Auth providers, Google (SHA-1, Android), Apple (developer account), Facebook (Meta app, Basic settings), deep links, and app store checklist.

---

## Project structure

```
lib/
├── main.dart                 # Entry, Supabase init
├── app.dart                  # Root routing (auth → couple link → onboarding → vault)
├── core/
│   ├── theme/               # Dual theme (Midnight Romance + Blush & Wink)
│   ├── constants/           # App constants, persona IDs, costs, breakpoints, achievement icons
│   ├── layout/              # ResponsiveVaultShell (desktop two-panel, mobile nav + FAB)
│   └── widgets/              # ErrorScreen, SkeletonCard, SkeletonMessageRow
├── features/
│   ├── auth/                # Welcome (WelcomeAuthScreen), login, couple link (invite code)
│   ├── couple/              # VaultSealedScreen (invite code + Share/Copy), LinkVaultScreen (pairing UI)
│   ├── season/              # SeasonRecapScreen (PageView recap, onFinish)
│   ├── onboarding/          # 3-screen onboarding (value prop, couple link, first surprise)
│   ├── vault/               # Vault list, create surprise (text/photo/voice), realtime
│   ├── battle/              # Submission, judge deliberation, reveal (text/photo/voice)
│   ├── treasure/            # Treasure archive, detail, replay battle view
│   ├── profile/             # Profile, achievement unlocked dialog
│   ├── home/                # Home tab
│   └── winks/               # Winks tab
├── models/                  # Surprise, Attempt, Couple, Judge, Achievement, etc.
├── providers/               # Riverpod: auth, couple, theme, onboarding, surprise, winks, AI judge, achievements, judges, season recap, streak
└── services/
    ├── ai_judge_service.dart       # Gemini Flash judge
    ├── encryption_service.dart    # Client-side encrypt/decrypt surprise content
    ├── realtime_service.dart      # Supabase Realtime channel for surprises
    ├── push_service.dart         # FCM token upsert (multi-device)
    ├── achievement_storage_service.dart   # Seen achievement IDs (shared_preferences)
    └── season_recap_storage_service.dart  # Seen season recap IDs (shared_preferences)
```

---

## Development Log

### February 23, 2026 – High-Level Planning & Concept Evolution

- **Session:** Creative kickoff with Winkidoo Master Architect.
- **Decisions:** MVP1 scope agreed: text-only surprises, 5 judge personas, persuade + collaborate unlock, dynamic score threshold, Gemini Flash, full Winks economy, dark mysterious UI, privacy (encryption + auto-delete), accessibility.
- **Deliverables:** Full Flutter app scaffold: auth, couple linking, create surprise (persona + difficulty + auto-delete), submission → AI judge → deliberation → reveal with confetti. Supabase schema and RLS. Realtime subscription for vault list. Winks balance (ensure row on first load). Encryption for surprise content. README and decision-log added.
- **Next steps:** Configure Supabase and Gemini keys, run migrations, test end-to-end. Add Wink+ and IAP later.

### February 23, 2026 – MVP1 Implementation

- **What we built:** Full Winkidoo MVP1 codebase.
  - Flutter app with dark theme (Midnight Romance palette).
  - Auth: email sign in/up via Supabase.
  - Couple linking: create link or join with code.
  - Vault: list surprises (for you / your vault), create surprise (text, unlock method, judge persona, difficulty, auto-delete).
  - Battle: submit text to judge → Gemini Flash returns score + commentary → deliberation screen → reveal (decrypt content + confetti if unlocked).
  - Winks: balance provider, ensure row with 10 Winks on first load, spend 1 Wink for extra attempt when daily free attempts exhausted.
  - Realtime: subscription on vault for new/updated surprises.
  - Privacy: client-side encryption for surprise content (key from couple id); auto-delete option (after viewing, 24h, 48h).
  - Accessibility: Semantics on main actions (e.g. sign in button).
- **Workflow:** Created pubspec, theme, constants; models (plain Dart with fromJson/toJson); providers (auth, couple, supabase, surprise, winks, AI judge); auth screens (login, couple link); vault (list, create surprise, realtime subscription); battle (submission, deliberation, reveal); services (encryption, AI judge, realtime); Supabase migration (tables + RLS); README and decision-log.
- **Tech:** Flutter 3.22+, Riverpod, Supabase Flutter SDK, google_generative_ai, encrypt, confetti, google_fonts.
- **Status:** Codebase complete; requires Supabase project + Gemini API key to run.
- **Next:** Run `flutter pub get`, apply migration, set env/dart-define, test flow. Then Wink+ subscription and polish.

### February 23, 2026 – Platform setup, config & couple flow

- **What we did:** Got the app running on macOS and Chrome; fixed Supabase 404s and “Something went wrong” after sign-in; hardened couple join flow.
- **Platform:** Flutter installed via Homebrew; `flutter create . --org com.winkidoo --project-name winkidoo` to add platform folders (ios, android, web, macos, windows, linux). CocoaPods installed with `brew install cocoapods` for macOS. Xcode Command Line Tools / Xcode required for macOS builds; `xcode-select -s /Applications/Xcode.app/Contents/Developer` if needed. For macOS network access, `com.apple.security.network.client` added to `macos/Runner/DebugProfile.entitlements` (and Release if needed).
- **Supabase config:** In `lib/main.dart`, added validation before `Supabase.initialize`: if `SUPABASE_URL` or `SUPABASE_ANON_KEY` are empty (from `String.fromEnvironment`), app shows `ConfigErrorApp` with instructions instead of initializing with empty URL (which caused 404 on `token?grant_type=password`). For local dev, default values for URL and anon key can be set in `main.dart`; for production use `--dart-define` and avoid committing keys in public repos.
- **“Something went wrong” (web):** The couples API returns 200 with `[]` when the user has no couple. `couple_provider.dart` was casting that to `Map` and throwing. Fixed by: (1) only parsing when `asMember is Map<String, dynamic>`, else return `null`; (2) wrapping the provider body in try/catch and returning `null` on any exception (with `debugPrint`), so the UI shows “Link with your partner” instead of the error branch.
- **Join flow:** In `couple_link_screen.dart`, the join-by-code response from Supabase may be non-Map on some platforms. We now treat `raw` as valid only when `raw is Map<String, dynamic>`, then read `res['id']` into `coupleId` and use it for the update. Avoids crashes and “Something went wrong” after join.
- **Realtime:** Supabase Realtime for `surprises` is enabled via Database → Publications → `supabase_realtime` → add `surprises` table.
- **Testing:** To test “create couple” and “join with code” correctly, use two different accounts (two emails): one creates the couple and gets the code; the other joins from another device. Using the same account on both shows “Invalid or already used code” once the code is consumed (same user in both slots). Chrome and macOS can run on the same machine; they share the same Supabase backend.
- **Status:** Auth and couple linking work on Chrome and macOS when config is set. Next: test with two accounts, then continue vault/judge flows and polish.

### Two-account flow and macOS verification

- **Goal:** Confirm that one account can create a couple and get a code, a different account can join with that code (e.g. on macOS), and macOS does not show “Something went wrong” after join or on the vault screen.
- **Provider hardening:** `surprisesListProvider` and `surpriseByIdProvider` now handle non-List / non-Map API responses and parse only valid Map items; on error they return empty list or null. `winksBalanceProvider` now checks `res is Map<String, dynamic>` and is wrapped in try/catch so it never throws. This avoids vault/home errors after join when Supabase returns unexpected shapes on some platforms.
- **Verification steps (manual):**
  1. **Chrome – Account A:** Run `flutter run -d chrome`, sign in as Account A, create a couple link, note the code (e.g. `ABC12XYZ`).
  2. **macOS – Account B:** Run `flutter run -d macos`, sign in as Account B (different email), enter the code from step 1, join. Confirm “You’re linked! Welcome to Winkidoo” and then the vault/home screen with no “Something went wrong.”
  3. If “Something went wrong” still appears, reproduce and check terminal for `coupleProvider:` debug prints; fix the cause (e.g. in `lib/providers/couple_provider.dart` or the screen that shows the error).
- **Success criteria:** Account B can join Account A’s couple from macOS; after join, macOS shows normal post-link UI (vault) and never “Something went wrong.”

### February 23, 2026 – AI Judge Pro Responses

- **Problem:** The AI judge often showed the same fallback (“Hold on, I'm still weighing this…”) repeatedly instead of substantive in-character replies. Gemini was returning valid JSON but with empty or very short `commentary`.
- **Approach:** (1) **Schema:** Use Gemini `GenerationConfig.responseSchema` (Dart `Schema.object` with `requiredProperties: ['commentary']`) so the API enforces a non-empty commentary field. (2) **Prompt:** Hardened `judgeChat` prompt with an explicit rule that commentary must be 1–3 full sentences in persona voice and never empty; added one example non-verdict JSON. (3) **Retry:** When the first response is valid JSON but commentary is empty/short, send one retry request with “Your previous reply had no commentary…” and use the second response if it has valid commentary. (4) **Fallbacks:** Replaced the single fallback string with a list of five varied messages and pick at random so the UI never repeats the same line. (5) **Context:** Added optional `surpriseContextHint` to `judgeChat` (e.g. “Surprise type: message”) and pass it from `BattleChatScreen` (derived from `surprise.unlockMethod`) so the judge can reference the surprise type without revealing content. (6) **Config:** Increased `maxOutputTokens` from 512 to 1024 so the model has room for full commentary.
- **Files:** `lib/services/ai_judge_service.dart` (schema, prompt, retry, varied fallbacks, `surpriseContextHint` param), `lib/features/battle/battle_chat_screen.dart` (pass `surpriseContextHint` into `judgeChat`).
- **Status:** Implemented. Judge should respond consistently with substantive, in-character commentary and varied fallbacks when needed.
- **Next:** Test live battle chat; tune persona examples or schema if needed.

### February 23, 2026 – Judge: Helpful "How to Impress" Answers and Less Repetition

- **Problem:** When the seeker (or creator) asked "what should I do to impress you?" or "how do you want to be impressed?", the Judge repeated the same deflection ("the magic comes from you", "bring your A-game") without giving concrete guidance. Responses felt repetitive.
- **Approach:** (1) **Rule:** Added an explicit prompt instruction that when users ask how to impress or how to win, the Judge must answer helpfully in character with 1–3 concrete ideas (no refusal without suggestions). (2) **Persona guidance:** New static map `_howToImpressByPersona` in `AiJudgeService` — each persona (Sassy Cupid, Poetic Romantic, Chaos Gremlin, The Ex, Dr. Love) has a short "what this judge wants" line (effort + sass, romantic language, chaos with heart, etc.). (3) **Unlock-method guidance:** From `surpriseContextHint`, inject a line for "persuade" (words, creativity, gesture) or "collaborate" (teamwork, shared effort). (4) **Optional `howToImpressHint`:** New optional parameter on `judgeChat()` for future game_mode or surprise_type hints (e.g. "Send a voice note", "Describe dream date in emojis"); battle screen passes `null` for now. (5) **Repetition:** Added instruction to vary reactions and give new angles or more concrete suggestions instead of repeating the same phrase when the user keeps asking. (6) **Example:** Added one in-prompt example of a good "how to impress" response (Sassy Cupid style) so the model has a clear pattern.
- **Files:** `lib/services/ai_judge_service.dart` (map, param, prompt blocks A/B/C, example), `lib/features/battle/battle_chat_screen.dart` (`howToImpressHint: null`).
- **Status:** Implemented. Judge should now give actionable, persona- and context-aware guidance when asked how to impress, and vary replies to reduce repetition.
- **Next:** Test in live chat; when game_mode or surprise_type are added to schema, pass `howToImpressHint` from battle screen.

### February 23, 2026 – AI Judge: Web Quote Detection and In-Character Nudges

- **Goal:** When a message sounds like a generic romantic quote, famous line, or copy-pasted web text, the Judge should respond in character with a warm, witty nudge that encourages original thinking — without shaming or literally accusing the user of copying.
- **Approach:** Prompt-only change in `judgeChat`: new rule (`webQuoteRule`) instructs the Judge to watch for web-quote-like phrasing (generic quotes, "According to…", search-result style) and respond with a clever, indirect nudge (e.g. "that had a little help from the internet", "tap into your own brain"). Two in-prompt examples: Sassy Cupid style and Poetic Romantic style, so the model keeps tone consistent. No schema or UI changes; the nudge lives in commentary only.
- **Files:** `lib/services/ai_judge_service.dart` (new `webQuoteRule` constant, injected into verdict instruction block; two example JSON responses).
- **Status:** Implemented. Judge may now respond with in-character web-quote nudges when it infers copied or generic text.

### February 23, 2026 – AI Judge: Vary Openers (No Repetitive "Oh Honey")

- **Problem:** The Judge (especially Sassy Cupid) repeated "Oh honey" at the start of messages too often, making replies feel samey.
- **Approach:** (1) **New rule:** Added `openerRule` in `judgeChat`: Judge must switch opening words every message — not start with "Oh honey" (or the same pet name) every time; use alternatives like "bestie", "sweetheart", "love", "darling", or no opener. Same for other personas (vary thy/thee, BRO, etc.). (2) **Sassy Cupid persona:** Updated from "Use phrases like 'Oh honey'" to "Vary your openers: sometimes 'Oh honey', sometimes 'bestie', 'sweetheart', 'love', 'darling', or jump straight in — never use the same opener two messages in a row." (3) **Examples:** Replaced repeated "Oh honey" in in-prompt examples with varied openers ("Bestie,…", "Sweetheart,…", and one with no opener) so the model sees variety.
- **Files:** `lib/services/ai_judge_service.dart` (`openerRule`, persona text, example commentary strings).
- **Status:** Implemented. Judge should now vary openers across messages and feel less repetitive.

### February 25, 2026 – Wink+ subscription and hint/instant-unlock polish

- **What we built:** (1) **Wink+ subscription (Supabase-backed):** New migration `003_wink_plus.sql` adds `wink_plus_until` (timestamptz) to `couples`. When set and in the future, the couple has Wink+. Couple model and provider now expose `isWinkPlus`. Benefits: Wink+ gets 10 free judge attempts per day (vs 3), and access to all 5 judge personas (Chaos Gremlin, The Ex, Dr. Love are gated as Wink+ only in Create Surprise). (2) **Provider:** `effectiveFreeAttemptsPerDayProvider` in `winks_provider.dart` returns 10 or 3 based on couple’s Wink+ status; `submission_screen.dart` uses it for attempt gating. (3) **Wink+ benefits screen:** New `WinkPlusScreen` lists benefits and shows “In-app purchase coming soon” for non-subscribers; vault header has a “Wink+” / “Wink+ ✓” chip that opens it. (4) **Create Surprise:** Premium personas (Chaos Gremlin, The Ex, Dr. Love) show a lock icon and “(Wink+)” and are disabled unless the couple has Wink+. (5) **Hint and instant-unlock UI:** Reveal and battle chat already had Get hint (5 Winks) and Unlock now (50 Winks); added Semantics for accessibility and switched button labels to use `AppConstants.hintCostWinks` and `AppConstants.instantUnlockCostWinks`.
- **Workflow:** Migration → Couple model + provider → effective free attempts → submission screen → create surprise persona gating → Wink+ screen + vault entry → reveal/battle semantics and constants.
- **Tech:** No new packages. Schema change only; IAP/Stripe can be wired later by setting `wink_plus_until` (e.g. via backend or admin).
- **Status:** Wink+ state and gating in place; paywall is placeholder. Hint/instant-unlock UI was already present; polished with semantics and constants.
- **Next:** Wire real IAP or Stripe to set `couples.wink_plus_until`. E2E test with two accounts; optionally add dev shortcut to grant Wink+ for testing.

### February 25, 2026 – Phase 1: Responsive UI, dual theme, onboarding, photo & voice surprises, quality

- **What we built:** Phase 1 roadmap delivered in order. (1) **Responsive & adaptive UI:** `LayoutBuilder` and `MediaQuery`; `ResponsiveVaultShell` in `core/layout/`. Web desktop (width ≥ 700px): two-panel layout — sidebar vault list (320px) + main area (battle/reveal/create) with nested `Navigator`. Mobile: full-screen flows, bottom nav (Vault), FAB for "Create Surprise". Breakpoint and `kIsWeb` used so desktop-only behavior is safe on web. (2) **Dual theme:** Full light theme "Blush & Wink" in `app_theme.dart` (light background, soft pinks, readable text); `AppTheme.gradientColors(Theme.of(context).brightness)` used on all gradient backgrounds. `ThemeModeNotifier` in `theme_provider.dart` persists theme mode (system/light/dark) in SharedPreferences; vault header has cycle toggle (system → light → dark). (3) **Micro-animations & haptics:** Reveal screen: `HapticFeedback.mediumImpact()` on successful unlock when `!kIsWeb`. Battle chat: send button with scale-down animation (0.88) on tap and `HapticFeedback.lightImpact()` on send; platform checks so web has no haptics. (4) **Onboarding & empty states:** 3-screen `OnboardingScreen` (value prop, couple link, first surprise) with "Get started"; `onboarding_provider.dart` persists completion; app shows onboarding once after login if not complete. Empty vault: illustration + "Nothing here yet" copy and "Create your first surprise" CTA. (5) **Photo surprise:** Migration `004_surprise_type_photo.sql` adds `surprise_type` (text/photo/voice) and `content_storage_path`. Supabase Storage bucket `surprises`; paths `{coupleId}/{surpriseId}.jpg`. Create flow: type selector (Text | Photo | Voice); photo = image_picker → upload binary → insert row with type + path. Reveal: signed URL for photo, `Image.network` when unlocked. (6) **Voice surprise:** Same schema; record via `record` package to temp `.m4a`, upload to Storage `{coupleId}/{id}.m4a`; reveal uses `audioplayers` with `UrlSource` for play/pause. (7) **Quality:** `ErrorScreen` widget (retry / back to vault); auth and couple error states in app show it. Vault loading shows 4 `SkeletonCard` placeholders; error state has Retry button. `flutter test`: app smoke test (ProviderScope + WinkidooApp) and `Surprise.fromJson` tests (text + photo). PWA: `web/manifest.json` and `web/index.html` title/description for installable web.
- **Workflow:** Constants (desktop breakpoint, storage bucket) → responsive shell + vault list (desktop nav key, bottom nav, FAB) → theme (light theme, provider, persist) → gradients switched to brightness-aware → onboarding provider + screen + app gate → empty vault UI → migration 004 → Surprise model (surpriseType, contentStoragePath, isPhoto, isVoice) → create surprise type selector, photo pick/upload, voice record/upload → reveal photo/voice signed URL + image/audio player → haptics and send-button animation → ErrorScreen, skeleton in vault, tests, manifest/meta.
- **Tech:** image_picker, record, audioplayers, path_provider; existing shared_preferences for theme and onboarding.
- **Status:** Phase 1 complete. All main screens theme-aware; web desktop and mobile layouts in place; photo and voice create/battle/reveal working; tests pass.
- **Next:** E2E smoke test (two accounts, full flow). Later: video/doodle surprises, push notifications, shareable reveal cards, Memory Wall, daily streak (Phase 2). Payments (IAP/Stripe) when ready.

### February 25, 2026 – Smoke-test polish: error screens, semantics, skeletons, copy

- **What we built:** Targeted polish from the smoke-test plan (Part 2). (1) **Error screens:** Vault list error state now uses full `ErrorScreen` (“Could not load surprises. Try again?”) with onRetry (invalidate surprisesListProvider). Battle chat: both messages-load error and full-screen surprise-load error use `ErrorScreen` with onRetry and onBack (pop). (2) **Accessibility:** Semantics added — submission screen “Submit to judge” button (`Send submission to judge`); battle chat send button (`Send message to judge`); create surprise type selector (group label with selected type) and “Lock it!” button (`Create surprise`). (3) **Battle chat loading:** New `SkeletonMessageRow` in `core/widgets/skeleton_message_row.dart` (left/right aligned placeholders). Battle chat initial load and messages load now show 3–4 skeleton rows instead of spinners; full-screen loading uses same gradient + skeleton list. (4) **Copy:** ErrorScreen default message set to “Something went wrong. Try again?”. AI Judge system prompt: added “Commentary tone: When praising or reacting, lean into wit and warmth — a little funny, a little romantic. Make the couple smile. Roasts should be playful, not mean.”
- **Workflow:** ErrorScreen in vault + battle chat → Semantics (submission, send, create) → SkeletonMessageRow + battle chat loading branches → ErrorScreen default + judge prompt tweak.
- **Status:** Smoke-test polish (Part 2) done. Manual smoke-test (Part 1) remains for you to run on devices.
- **Next:** Run manual smoke-test (two accounts, vault/create/battle/reveal, platform checks). Then Phase 2 (video/doodle, push, shareable cards, Memory Wall, streak) or payments.

### February 25, 2026 – Blueprint v1 Phase 1: schema, vault copy, difficulty, treasure archive, judges

- **What we built:** Schema and app aligned to [PRODUCT_BLUEPRINT.md](PRODUCT_BLUEPRINT.md). (1) **Migration 005:** Added to `surprises`: `battle_status`, `archived_flag`, `seeker_score`, `resistance_score`, `fatigue_level`, `last_activity_at`, `winner`, `creator_defense_count`. Created `treasure_archive` and `judges` (with seed rows). (2) **Surprise model:** Extended with new fields; create/update flows set `battle_status`. (3) **Difficulty:** Base values Easy 80, Medium 100, Hard 130 in `app_constants.dart` (plus Chaos variance). (4) **Vault copy:** Sections labeled **Waiting for You** (partner’s) and **Your Surprises** (yours). (5) **Models:** `TreasureArchive` and `Judge`; app ready for Result Summary and Keep in Treasure / Delete flows. Migrations 001–002 made idempotent (drop policy if exists, publication add only if not present) so re-runs are safe.
- **Status:** Blueprint v1 Phase 1 schema and UX plan in place; docs (README, migrations README) updated. Manual smoke-test and Phase 2 (Result Summary UI, tug-of-war meter, seasonal judges) when ready.

### February 26, 2026 – Realtime Sync Layer (before UI polish)

- **What we built:** Realtime sync so the battle screen always reflects live state and navigates to reveal exactly once when a surprise is resolved (locally or by partner). Done before UI polish so animations use correct, up-to-date state. (1) **Migration 008:** `008_realtime_surprises.sql` adds `public.surprises` to `supabase_realtime` publication (idempotent, same pattern as 002) so the surprise row stream receives UPDATE events (e.g. `battle_status` → `resolved`). (2) **BattleRealtimeService:** Extended with a second `onPostgresChanges` on the same channel: table `surprises`, filter `id` = surpriseId, event UPDATE; optional callback `onSurpriseChanged(PostgresChangePayload)` so the UI can invalidate providers and auto-navigate. (3) **BattleChatScreen:** Subscribes with `onSurpriseChanged: _onSurpriseRowChanged`. Callback invalidates `surpriseByIdProvider`, `surprisesListProvider`, and `battleMessagesProvider`; when `payload.newRecord['battle_status'] == 'resolved'` and `!_navigatedToVerdict` and still on battle route, fetches verdict message, builds `JudgeResponse` from it, sets `_navigatedToVerdict = true`, then `context.go` to reveal with extra. (4) **Double-navigation guard:** `_navigatedToVerdict` set to `true` before `context.go` in: local seeker-win path in `_sendMessage`, instant-unlock path in `_buyInstantUnlock`, and realtime path in `_onSurpriseRowChanged`; verdict-in-messages path already set it before scheduling navigation.
- **Workflow:** Migration 008 → BattleRealtimeService (surprise row stream + callback) → BattleChatScreen (onSurpriseChanged, invalidate, resolve detection, fetch verdict, single guard, context.go).
- **Tech:** Supabase Flutter `onPostgresChanges` for `surprises` table filtered by row id; no new packages.
- **Status:** Realtime sync layer complete. Battle screen auto-reacts to surprise row updates; partner sees auto-navigation to reveal when seeker resolves; local resolver does not double-navigate when surprise-row event arrives later.
- **Next:** UI polish (animations, transitions); manual smoke-test with two devices to confirm realtime resolve flow.

### February 26, 2026 – Couple stats, Treasure Archive 2.0, Achievements, Season recap, Judges, Pre-battle tease, Push (full session)

- **Couple Stats ("Your Dynamic"):** `lib/providers/couple_stats_provider.dart` — `CoupleStats` (totalBattles, unlockRate, toughestJudgePersonaId, avgPersuasion, creatorDefenseRatio, monthlyBattles) computed from resolved surprises; `coupleStatsProvider` watches couple + surprisesListProvider. Profile screen: "Your Dynamic" section with stat cards (Total Battles, Unlock Rate, Toughest Judge, Avg Persuasion, Creator interventions) and custom monthly bar chart (last 6 months); empty state when no battles.
- **Treasure Archive 2.0:** Redesigned archive as memory vault. `treasure_archive_screen.dart` — cards with judge portrait, outcome badge, date, difficulty, attempts, mini persuasion/resistance meter; blur + lock overlay for non–Wink+; tap → detail. Route `/shell/treasure-archive/:surpriseId` → `TreasureDetailScreen`: free users see summary + "Unlock full memory with Wink+"; Wink+ see full surprise content, battle chat replay, "Replay Battle". `replay_battle_view.dart` — sequential message + meter replay (no new schema). `archiveWithSurprisesProvider` (or list + surpriseById per card) for enriched cards. Premium gating via `effectiveWinkPlusProvider`; no blocking of navigation.
- **Achievements (Phase 1):** `lib/models/achievement.dart` (id, title, description, unlocked, unlockedAt). `lib/providers/achievements_provider.dart` — depends on coupleStatsProvider + surprisesListProvider; computes First Victory, 5/10 Battles, 100+ Persuasion, Beat Chaos Gremlin, 3+ Creator Defenses, Active 3 Months; read-only, retroactive. Profile: "Achievements" below "Your Dynamic" — horizontal scroll of circular badges; locked = grayscale + lock overlay, unlocked = colored + glow; tap → bottom sheet (title + description). Icons in `lib/core/constants/achievement_icons.dart`.
- **Achievements (Phase 2 — Unlock celebration):** `lib/services/achievement_storage_service.dart` — shared_preferences, getSeenAchievements/markAsSeen. `AchievementUnlockedDialog` — scale 0.8→1, fade 250ms, haptic on open; "Achievement Unlocked", icon, title, description, "Nice." Detection on Home and Profile: when achievements load, compare with seen IDs; show modal for first new unlock, then mark seen. Guard so runs once per screen load. Unlock detection also on Home for earlier celebration when user returns from battle.
- **Celebration order (Home):** Single sequence so season recap takes priority over achievement modal. When both providers have data, `_runCelebrationSequence` runs: first `_checkSeasonRecap`, then `_checkNewUnlocks`. One guard `_checkedHomeCelebrations`; no duplicate fires.
- **Season Recap trigger:** `lib/services/season_recap_storage_service.dart` — hasSeenSeason(seasonId), markSeasonSeen(seasonId). HomeScreen watches `seasonRecapProvider`; when recap != null and !hasSeenSeason, push SeasonRecapScreen with onFinish (markSeasonSeen + pop) and onReplayHighlight (pop + push treasure-archive/:id). Guard `_checkedSeasonRecap` (now folded into `_checkedHomeCelebrations` with achievements). No provider or DB changes.
- **Data-driven judges:** Migration 011 — judges table extended (tagline, difficulty_level, chaos_level, tone_tags, preview_quotes, primary_color_hex, created_at, is_premium; season_start/season_end timestamptz). Judge model: selectionList removed; fromJson for DB; Judge.placeholder(personaId). `activeJudgesProvider` and `judgeByPersonaIdProvider(personaId)` in judges_provider. JudgeSelectionScreen uses activeJudgesProvider (loading/empty); CreateSurpriseScreen passes isJudgeLocked from judge.premiumFlag. Seasonal badge ("Limited Time", "Ends in X days") and "New" badge (migration 012 is_new; client hides after 7 days).
- **Judge Selection 2.0:** Full-screen judge selection (aura, portrait, difficulty/chaos meters, tone tags, rotating preview quotes, "Seal with This Judge"); vault sealing transition (portrait scale, aura intensify, "The vault is sealed." overlay, then onSelect). Pre-battle tease before battle chat: PreBattleTease (aura, portrait, lock pulse, random quote, "Begin Persuasion"); 1.5s auto-advance or tap; BattleChatScreen shows tease first then chat.
- **Season-launch push:** Migration 013 — judges.season_push_sent. Edge Function send_battle_notification extended: on table `judges` (INSERT/UPDATE), when seasonal + season just started + is_new + !season_push_sent, send "✨ A New Judge Has Arrived" to all user_push_tokens; then update judge set season_push_sent = true. Second Database Webhook on `public.judges` (INSERT, UPDATE) to same function URL. App deep link type `season_launch` → router.go('/shell/create').
- **Push (Firebase + FCM):** Migrations 009–010 (user_push_tokens, multi-device). Firebase project: Android (package com.winkidoo.winkidoo), iOS, Web. google-services.json and GoogleService-Info.plist in android/app/ and ios/Runner/ (gitignored). Web: Firebase SDK + firebaseConfig in web/index.html. Edge Function deployed; FIREBASE_SERVICE_ACCOUNT secret set (never in repo). Webhooks: surprises and judges. push_service.dart upserts token on login and onTokenRefresh. Deep links: surprise_id → battle or reveal; season_launch → create. See docs/FIREBASE_AND_PUSH_SETUP.md.
- **Known issues / future:** (1) Photo lock: StorageException "Bucket not found" — ensure Supabase Storage bucket `surprises` exists and policies allow upload/read. (2) Voice note: UI shows "Recording... tap to stop" but recording may need device permissions and record package compatibility (record_linux version conflict on desktop; pin record to compatible version for Android). (3) Future: filter push tokens by updated_at last 90 days or users in a couple; idempotency in Edge Function for unrelated field updates.

### February 25–26, 2026 – Documentation and project memory update

- **What we did:** Updated project documentation and memory to reflect the full current state. (1) **README:** Project structure now lists `SkeletonMessageRow` in `core/widgets/`. Development log already contained smoke-test Part 2 (error screens, semantics, skeletons, judge tone), Blueprint v1 schema/vault/difficulty/treasure/judges, Phase 1 (responsive UI, dual theme, onboarding, photo/voice, quality), Wink+ and hint/instant-unlock, and Feb 26 realtime sync layer. (2) **Push notifications (Firebase/FCM):** Migrations 009 (`user_push_tokens`) and 010 (multi-device: `id` PK, `push_token` unique); Firebase project with Android/iOS/Web apps; configs in `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` (gitignored); web config in `web/index.html`; `push_service.dart` upserts with `onConflict: 'push_token'`; Edge Function `send_battle_notification` (relevant-field check, idempotency). Full checklist: **docs/FIREBASE_AND_PUSH_SETUP.md**. (3) **Validation:** LOCAL_VALIDATION.md is the run-locally checklist (error paths, semantics, skeletons, judge tone, then Part 1 manual smoke-test). (4) **Memory:** Project state and “what’s done / what’s next” captured for future sessions.
- **Status:** Docs and memory up to date. Next: run app locally, run LOCAL_VALIDATION checklist, then Part 1 manual smoke-test (two accounts); optionally deploy Edge Function and webhook for push.

### February 26, 2026 – App stuck on loading screen (CoupleLinkScreen) fix

- **Problem:** On launch (e.g. Android), the app sometimes showed a full-screen dark gradient with a pink circular loading spinner and never progressed. Console showed surface/visibility logs; user was stuck.
- **Cause:** The spinner matches **CoupleLinkScreen**: (1) when the user was already linked, the screen showed a spinner and relied only on router redirect to go to the vault — if redirect didn't run or was delayed, they stayed stuck; (2) when `coupleProvider` stayed in a loading state (e.g. slow/failing network or Supabase), the loading UI never cleared.
- **What we built:** (1) **Explicit navigation when linked:** In `lib/features/auth/couple_link_screen.dart`, when `couple != null && couple.isLinked`, we now call `context.go('/shell/vault')` in a post-frame callback so the app always navigates to the vault even if the router redirect hasn't fired. (2) **Loading timeout and retry:** Replaced the infinite loading state with `_CoupleLinkLoadingBody`: after 8 seconds it shows "Taking too long? Check your connection and try again." and a **Retry** button that invalidates `coupleProvider` and resets the timeout. Added `go_router` import and `kCoupleLoadTimeout` (8s).
- **Workflow:** Identified CoupleLinkScreen as source of spinner → added post-frame `context.go` for linked case → extracted loading branch to stateful widget with Timer, timeout message, and retry.
- **Files:** `lib/features/auth/couple_link_screen.dart` (navigate when linked; `_CoupleLinkLoadingBody` with timeout + retry).
- **Status:** Implemented. Users no longer stuck indefinitely on the couple-link loading screen; retry gives a path when the couple fetch hangs.
- **Next:** Run app again; if a spinner appears before sign-in (initial auth check), we can add a dedicated auth-loading screen and/or logging.

### February 27, 2026 – Creator flow, premium screens, OAuth/store setup, domain

- **Router — creator vs linked flow:** When user has a couple but partner has not joined yet (`hasCouple == true` and `!isCoupleLinked`), redirect goes to **/vault-sealed** (not vault). When `isCoupleLinked == true`, redirect goes to **/shell/vault**. This gives creators a dedicated “Vault Sealed” screen with invite code and Share/Copy while waiting for partner; once linked, both go to vault. Implemented in `app.dart` (routerRefreshNotifier with `isCoupleLinked`) and `app_router.dart` redirect logic.
- **Vault Sealed screen redesign:** Replaced with presentational **VaultSealedScreen(inviteCode)**. No Riverpod/go_router/Supabase in screen file. Three-layer background: linear gradient (navy → plum), radial plum glow (center 0,-0.2, radius 0.8, 0.25 opacity), optional vignette. Content: “VAULT SEALED” label, headline “Your private vault is ready.”, subtext, hero card with formatted code (XXXX–XXXX if length 8), “Share Invite” (primary) and “Copy Code” (outlined) buttons — UI only, no share/copy implementation. Load animation: FadeTransition + ScaleTransition (0.97→1, 250ms easeOut). Route **/vault-sealed** uses Consumer + coupleProvider; builds `VaultSealedScreen(inviteCode: couple.inviteCode)` when couple present and not linked; otherwise gradient + CircularProgressIndicator.
- **Welcome/Auth screen:** **WelcomeAuthScreen** — full-screen background image (`assets/images/welcomepage_background.png`), optional radial overlay; title “Sign in or Create your vault”, subtitle, email field, Continue (Poppins 18px, letterSpacing 0.5, AnimatedScale 0.97), divider “or”, Google (white bg, Google logo asset) and Apple (transparent bg, white 0.3 border, Apple logo asset) buttons, footer (Terms/Privacy, “Already have an account? Sign In”). Fade-in on load (200–250ms). Root route **/** shows WelcomeAuthScreen; Continue/Sign In/Google/Apple wire to auth (login or OAuth). Logo assets: `assets/images/google_logo.png`, `assets/images/apple_logo.png`.
- **Link Vault screen (UI only):** **LinkVaultScreen** in `lib/features/couple/link_vault_screen.dart`. Same navy–plum gradient + radial glow as other premium screens. Reusable **_VaultOptionCard** (title, description, child). Card 1: “Create a new vault” / “We’ll generate a private invite code…” / “Create Vault” button (tap scale 0.97). Card 2: “Join with a code” / invite code TextField + “Join Vault” outlined button. Footer: “One vault. One partner. Infinite persuasion.” No navigation or Supabase; wiring to create/join logic can be done when route is added.
- **Season Recap screen (UI only):** **SeasonRecapScreen** in `lib/features/season/season_recap_screen.dart`. Accepts **SeasonRecap** model and **onFinish** callback. PageView with 6 slides: (1) Season intro (title, judge placeholder, “Your story this season”), (2) Performance (battles played, win rate, avg persuasion), (3) Streak (longest streak, warm styling), (4) Achievements (horizontal badges from achievementIcons), (5) Highlight duel (preview + “Replay This Battle” if highlightSurpriseId; else empty state), (6) Closing CTA (“Next season begins now.” + “Continue” calling onFinish). Dark gradient, dot indicators, no provider/DB in screen.
- **OAuth and store setup (no secrets in repo):** Google OAuth: Supabase Auth → Google provider enabled; Android requires SHA-1 from debug/release keystore. Get SHA-1: ensure Java available (e.g. Android Studio JBR: `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"`), then `cd android && ./gradlew signingReport`; add the SHA-1 and package name in Google Cloud Console OAuth client (Android) and paste Client ID in Supabase. Apple: Sign in with Apple requires Apple Developer Program ($99/year); configure in Supabase and Apple Developer; can ship Android-first without Apple. Facebook (Meta): App created in Meta for Developers; Facebook Login product; Basic settings: App icon 1024×1024, Privacy policy URL, User data deletion URL (e.g. data-deletion.html), Category (e.g. “Social networks & dating”), Contact email. Do not commit App ID, Client Token, or App Secret in public repos; set in Supabase Auth providers and in app via env or build config. See **docs/OAUTH_AND_STORE_SETUP.md** for step-by-step (no keys).
- **Deep links:** For mobile OAuth callback, configure app URL scheme (e.g. `winkidoo://`) in iOS/Android and add the redirect URL (e.g. `winkidoo://auth/callback`) to Supabase Auth → URL configuration so the app returns from browser after sign-in.
- **Domain and GitHub Pages:** Custom domain **winkidoo.com**. GitHub repo: **github.com/abybiju/Winkidoo**. Pages: Deploy from branch **main**, folder **/docs**. Site available at **https://abybiju.github.io/Winkidoo/**; custom domain can be set in repo Settings → Pages → Custom domain (winkidoo.com). DNS (GoDaddy): A records for **@** (root) point to GitHub Pages IPs (185.199.109.153, 185.199.110.153, 185.199.111.153). If **www** is used, CNAME **www** → **abybiju.github.io** (note: existing CNAME www → winkidoo.com can conflict; use root for Pages or adjust CNAME). Privacy policy: **https://winkidoo.com/privacy-policy.html** (or GitHub Pages URL until DNS propagates). Data deletion: **docs/data-deletion.html** → **https://winkidoo.com/data-deletion.html**.
- **App store / Meta submission:** For store or Meta app review, ensure: App icon 1024×1024 (e.g. assets/images/app_icon_1024.png), Privacy policy URL, User data deletion URL, Category. Meta Basic settings completed with above; Apple/Google Play can be done later (Apple requires paid developer account).
- **Status:** Creator flow and Vault Sealed UX in place; welcome and link-vault screens ready for auth wiring; season recap ready for caller; OAuth and domain documented without secrets. Repo pushed to GitHub.
- **Next:** Wire Share/Copy on Vault Sealed (share_plus, Clipboard); optionally add “Enter Vault” or “Waiting for partner…” on same screen; connect LinkVaultScreen to router and couple create/join logic; run E2E with Google/Apple/Facebook OAuth when credentials are set.

---

### February 27, 2026 – Connection Streak, Season Recap Provider (data layer), recap query optimization

- **Connection Streak (Light Streak Mechanic):** Read-only weekly activity streak; no DB or achievement changes. (1) **Provider:** `lib/providers/streak_provider.dart` — `StreakStats` (currentStreak, longestStreak, activeThisWeek) computed from resolved surprises (`resolvedAt`). ISO week via Thursday method (year + week number); unique active weeks from resolved dates; current streak = consecutive weeks backward from "this week" (0 if this week inactive); longest streak = max run of consecutive weeks with year transition (week 52 → week 1) handled. No couple or no resolved battles → (0, 0, false). (2) **Profile UI:** New section "Connection Streak" in `lib/features/profile/profile_screen.dart` between "Your Dynamic" and "Achievements": flame icon, warm gradient card (orange/deepOrange); large current streak ("X weeks" / "1 week"), subtitle "Keep the spark alive.", longest streak below; when not active this week, subtle line "Play a battle this week to continue your streak."; optional glow (elevation + border) when currentStreak ≥ 3. Loading/error same pattern as Your Dynamic (card + CircularProgressIndicator or "—").
- **Season Recap Provider (data layer only):** Read-only recap for the most recently ended seasonal judge. (1) **File:** `lib/providers/season_recap_provider.dart`. (2) **Model:** `SeasonRecap` — seasonId (judge personaId), seasonTitle (judge name), seasonStart, seasonEnd; battlesPlayed, winRate, avgPersuasion; longestStreakDuringSeason (consecutive active weeks within season window only); achievementsUnlockedDuringSeason (achievements whose first-unlock date falls in [seasonStart, seasonEnd]); highlightSurpriseId (surprise id with highest resistance_score, tie-break smallest |resistance − seeker|). (3) **Logic:** Detect most recently ended seasonal judge (season_end < now, order by season_end desc, take first). Filter resolved surprises to [seasonStart, seasonEnd]. Compute battlesPlayed, winRate, avgPersuasion; longest streak via duplicated ISO-week helpers (same algorithm as streak_provider, scoped to season dates); first-unlock date per achievement from global resolved (sorted by resolvedAt) then filter by window; highlight = max resistance_score then min gap. Return null if no ended season. No DB writes; no push; no UI in this provider. (4) **Achievement unlock derivation:** first_victory = first seeker win; battles_5/10 = 5th/10th resolved; persuasion_100 = first battle with seekerScore ≥ 100; beat_chaos_gremlin = first chaos_gremlin seeker win; creator_defenses_3 = first with creatorDefenseCount ≥ 3; active_3_months = battle that first brings distinct-month count to 3.
- **Recap judges query optimization:** Instead of fetching all judges and filtering client-side, season recap now uses a single Supabase query: `.lt('season_end', now.toIso8601String())`, `.not('season_start', 'is', null)`, `.order('season_end', ascending: false)`, `.limit(1)`. One row returned when a recap exists; scales when the judges table grows.
- **Status:** Connection Streak and Season Recap data layer in place; docs updated. No secrets in repo.
- **Next:** Optional: Season Recap UI already exists (SeasonRecapScreen); wire Home (or other entry) to show recap when `seasonRecapProvider` is non-null and not yet seen. Continue with Share/Copy on Vault Sealed, LinkVaultScreen wiring, E2E OAuth.

---

## Git

```bash
git add .
git commit -m "docs: Feb 27 — Connection Streak, Season Recap Provider (data layer), recap query optimization; update memory"
git push
```
