# Winkidoo

**AI-powered Digital Surprise Vault for couples.** One person hides a message (or future: photo, voice, gift). Both can play: convince the AI judge to unlock it. Winner gets the reveal.

- **Stack:** Flutter 3.22+, Supabase (Auth, Realtime, Postgres, Storage), Riverpod 2.x, Google Gemini Flash (AI Judge).
- **Vibe:** Dark mysterious romance UI, 5 judge personas, persuasion or collaboration unlock, Winks virtual economy.

---

## Setup

1. **Flutter**
   - Install [Flutter 3.22+](https://flutter.dev).
   - If `android/` and `ios/` are missing, run: `flutter create . --org com.winkidoo --project-name winkidoo`.
   - Run `flutter pub get`.

2. **Supabase**
   - Create a project at [supabase.com](https://supabase.com).
   - Run the schema: copy contents of `supabase/migrations/001_initial_schema.sql` into SQL Editor and run.
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

4. **Realtime (optional)**
   - In Supabase Dashboard → Database → Replication, add `surprises` table to the publication so new surprises push to the app.

---

## Project structure

```
lib/
├── main.dart                 # Entry, Supabase init
├── app.dart                  # Root routing (auth → couple link → vault)
├── core/
│   ├── theme/               # Midnight Romance dark theme
│   └── constants/           # App constants, persona IDs, costs
├── features/
│   ├── auth/                # Login, couple link (invite code)
│   ├── vault/               # Vault list, create surprise, realtime subscription
│   └── battle/              # Submission, judge deliberation, reveal
├── models/                  # Surprise, Attempt, Couple, JudgeResponse, WinksBalance
├── providers/               # Riverpod: auth, couple, surprise, winks, AI judge
└── services/
    ├── ai_judge_service.dart   # Gemini Flash judge
    ├── encryption_service.dart # Client-side encrypt/decrypt surprise content
    └── realtime_service.dart   # Supabase Realtime channel for surprises
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

---

## Git

```bash
git add .
git commit -m "feat: Winkidoo MVP1 — auth, vault, judge, reveal, winks, realtime ✨"
git push
```
