# Winkidoo — Claude Code Context

Winkidoo is an AI-powered couples' surprise vault game built with Flutter. One partner (creator) hides a surprise (text, photo, or voice); the other (seeker) must persuade a Gemini-powered AI judge to unlock it through a live chat battle. Both partners participate in real time via Supabase Realtime. The app targets iOS, Android, Web, and macOS.

---

## Build and Run

```bash
# Install dependencies
flutter pub get

# Run (all three --dart-define flags required)
flutter run \
  --dart-define=SUPABASE_URL=<your_url> \
  --dart-define=SUPABASE_ANON_KEY=<your_anon_key> \
  --dart-define=GEMINI_API_KEY=<your_gemini_key>

# Target a specific device
flutter run -d chrome        # Web
flutter run -d macos         # macOS
flutter run -d android       # Android
flutter run -d ios           # iOS

# Tests and lint
flutter test
flutter analyze
```

**Important:**
- `SUPABASE_URL` or `SUPABASE_ANON_KEY` empty → `ConfigErrorApp` renders with instructions (see `lib/main.dart:20`). The app will NOT launch normally.
- `GEMINI_API_KEY` missing → app launches fine, but battles throw during judge calls. Set it even for non-battle testing to avoid runtime errors.
- Firebase is optional — `Firebase.initializeApp()` is wrapped in try/catch (`lib/main.dart:10`). Push notifications are a no-op if `google-services.json` / `GoogleService-Info.plist` are absent.

---

## Repo Structure

```
lib/
  main.dart                        # Firebase+Supabase init; ConfigErrorApp guard
  app.dart                         # Root ConsumerStatefulWidget; push setup; OAuth deep links; router listener
  router/
    app_router.dart                # GoRouter config; RouterRefreshNotifier; all routes
  core/
    theme/app_theme.dart           # All color tokens + brightness-aware helpers; light+dark themes
    constants/
      app_constants.dart           # All magic numbers: persona IDs, Wink costs, difficulty thresholds, breakpoints
      judge_asset_map.dart         # Persona-to-asset resolver (gender-aware)
      avatar_presets.dart          # Preset avatar asset definitions
    layout/
      responsive_vault_shell.dart  # Desktop 2-panel (>=700px) / mobile 1-panel
    widgets/                       # Shared: WinkCard, PillCta, WinkBottomNav, WinkidooTopBar, SkeletonCard, etc.
  features/
    auth/                          # WelcomeAuthScreen, LoginScreen, CoupleLinkScreen
    couple/                        # VaultSealedScreen (invite code waiting state)
    home/                          # HomeScreen (avatar rail, judge spotlight, recent wins)
    vault/                         # VaultListScreen, CreateSurpriseScreen, WinkPlusScreen, RealtimeSurprisesSubscription
    battle/                        # BattleChatScreen, JudgeDeliberationScreen, RevealScreen, PersuasionMeter
    treasure/                      # TreasureArchiveScreen, TreasureDetailScreen
    profile/                       # ProfileScreen (edit, stats, achievements, settings)
    season/                        # Season recap storage service + screen
    onboarding/                    # OnboardingScreen (3 slides)
    play/                          # PlayScreen (tab: dares, mini-games, packs, campaigns, judges, character chat)
    character_chat/                # AI Character Chat: rooms, chat, friends, group creation
    winks/                         # WinksTabScreen (legacy — replaced by Play tab, balance in Profile)
  models/                          # Plain Dart data classes (no business logic)
  providers/                       # Riverpod providers (state layer)
  services/                        # Business logic and external service wrappers
supabase/
  migrations/                      # SQL files 001–013 + 010_profiles_avatar; run in numeric order
  functions/
    send_battle_notification/      # Edge Function for push notifications
docs/
  ARCHITECTURE.md                  # Provider graph, feature layout, data flow patterns
  DATABASE.md                      # Schema, migration map, RLS, RPCs, Realtime
  PROJECT_STATE.md                 # Session memory: what's implemented, what's next
  FIREBASE_AND_PUSH_SETUP.md       # Firebase project setup + Edge Function deployment
  STORAGE_SETUP.md                 # Supabase Storage bucket policies
  OAUTH_AND_STORE_SETUP.md         # Google/Apple/Facebook OAuth + app store checklist
PRODUCT_BLUEPRINT.md               # Game mechanics source of truth (personas, DRS formula, Wink+)
LOCAL_VALIDATION.md                # Manual two-account smoke-test checklist
decision-log.md                    # Why key architectural choices were made
```

---

## Architecture Overview

Feature-first layout under `lib/features/`. Each feature contains only screen widgets — providers live in `lib/providers/`, services in `lib/services/`, and data classes in `lib/models/`. Never import between feature directories directly.

State is managed exclusively with **Riverpod**. Use `ref.watch` for reactive reads and `ref.invalidate(provider)` after Supabase mutations — never call manual re-fetch methods. Do not use `setState` for business data; only for transient local UI state within a single widget.

Navigation uses **GoRouter 17** with `StatefulShellRoute.indexedStack` for the 4-tab shell. `RouterRefreshNotifier` drives all redirect logic; call `routerRefreshNotifier.update(...)` from `app.dart` whenever auth/couple/onboarding state changes.

See `docs/ARCHITECTURE.md` for the full provider dependency graph, service responsibilities, and end-to-end data flow.

---

## State Management Conventions

| Pattern | Provider type | Examples |
|---|---|---|
| Auth stream | `StreamProvider` | `authStateProvider` |
| Async with imperative methods | `AsyncNotifierProvider` | `coupleProvider` |
| Read-only async data | `FutureProvider` | `surprisesListProvider`, `achievementsProvider`, `streakProvider` |
| Parametric queries | `FutureProvider.family` | `surpriseByIdProvider(id)`, `judgeByPersonaIdProvider(personaId)`, `battleMessagesProvider(id)` |
| Simple mutable UI state | `StateProvider` | `themeModeProvider`, `partnerAddedSurpriseAtProvider` |

**Key rules:**
- After any Supabase mutation, call `ref.invalidate(theProvider)` — do not manually re-fetch.
- `achievementsProvider` and `streakProvider` are **computed client-side** from `surprisesListProvider` — there is no DB table for achievements or streaks.
- `coupleStatsProvider` is also computed from surprises data — no DB table.

---

## Navigation

GoRouter with `StatefulShellRoute.indexedStack`. Shell tabs:
- `index 0` → `/shell/home`
- `index 1` → `/shell/vault`
- `index 2` → `/shell/play`
- `index 3` → `/shell/profile`

Center FAB taps → `context.push('/shell/create')` (not a tab branch).

**Rules:**
- Always use `context.go()` or `context.push()` — never `Navigator.push` cross-feature.
- Pass route data via GoRouter `extra` as `Map<String, dynamic>` (see `/shell/deliberation` and `/shell/reveal/:id`).
- `RouterRefreshNotifier` in `lib/router/app_router.dart` drives redirects. Call `.update(...)` from `app.dart` when auth/onboarding/couple state changes.

**Redirect state machine:**
```
authLoading == true          → stay (null)
unauthenticated              → '/'
authenticated + !onboarding  → '/onboarding'
authenticated + !couple      → '/couple-link'
authenticated + couple + !linked → '/vault-sealed'
authenticated + couple + linked  → '/shell/vault'
```

---

## Encryption

All surprise content is encrypted client-side before writing to Supabase. The server only stores ciphertext.

- **Algorithm:** AES-256 (CBC mode via `encrypt` package)
- **Key derivation:** `coupleId + 'winkidoo-v1'`, UTF-8 encoded, zero-padded to 32 bytes, base64-encoded
- **Ciphertext format:** `<iv_base64>:<ciphertext_base64>`
- **Service:** `lib/services/encryption_service.dart`

```dart
// Always pass coupleId — never omit it in production code paths
final cipher = await EncryptionService.encrypt(plainText, coupleId: couple.id);
final plain  = await EncryptionService.decrypt(cipher,    coupleId: couple.id);
```

Passing `coupleId: null` falls back to a hardcoded dev key (`'default-key-for-mvp-32bytes!!'`). Data encrypted with the fallback key is unreadable in production. Never use `coupleId: null` in production code paths.

---

## Realtime

Two tables are in the Supabase Realtime publication: `surprises` (migration 008) and `battle_messages` (migration 002).

**Vault subscription** — `RealtimeSurprisesSubscription` widget (`lib/features/vault/`):
- Channel: `'vault:${coupleId}'`
- Filters on `surprises` table, `couple_id = eq.<coupleId>`
- On any change: calls `ref.invalidate(surprisesListProvider)` and sets `partnerAddedSurpriseAtProvider`

**Battle subscription** — `BattleRealtimeService` (`lib/services/`):
- Channel: `'battle:${surpriseId}'` (one instance per active battle)
- Subscribes to `battle_messages` filtered by `surprise_id` AND the specific `surprises` row for resolution
- Guards against re-subscribing to the same `surpriseId`
- **Always call `dispose()` in widget's `dispose()`** to unsubscribe the channel

---

## Database Migration Workflow

Migrations live in `supabase/migrations/` and are run **manually** in numeric order via the Supabase SQL Editor (Dashboard → SQL Editor → New query). There is no automated migration runner.

When adding a new migration:
1. Create `supabase/migrations/<NNN>_<description>.sql`
2. Update `supabase/migrations/README.md`
3. Update `docs/DATABASE.md` — migration table and affected schema sections
4. If new columns are added to a model-backed table, update `fromJson`/`toJson` in `lib/models/`

See `docs/DATABASE.md` for the full schema, migration map, RLS policies, RPCs, and realtime setup.

---

## Testing

```bash
flutter test       # unit tests in test/
flutter analyze    # zero warnings policy
```

- Integration testing: follow `LOCAL_VALIDATION.md` — two-account manual smoke test covering vault, battle, reveal, and error paths.
- No widget tests currently. When adding logic to providers or services, add a corresponding unit test in `test/`.

---

## Environment Variables

| Variable | Where used | Required |
|---|---|---|
| `SUPABASE_URL` | `lib/main.dart` via `String.fromEnvironment` | **Yes** — app shows `ConfigErrorApp` if empty |
| `SUPABASE_ANON_KEY` | `lib/main.dart` via `String.fromEnvironment` | **Yes** — app shows `ConfigErrorApp` if empty |
| `GEMINI_API_KEY` | `AppConstants` → `AiJudgeService` | **Yes for battles** — throws on any judge call |
| `FIREBASE_SERVICE_ACCOUNT` | Supabase secret (Edge Function only) | Push notifications only |

All keys are passed via `--dart-define`. No `.env` file. No defaults in the codebase.

---

## What NOT to Do

1. **Do not commit secrets.** `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GEMINI_API_KEY` are `--dart-define` only. No defaults exist by design (`lib/main.dart:17-18`).

2. **Do not hardcode color literals.** All colors come from `AppTheme` tokens (`lib/core/theme/app_theme.dart`). The theme has both dark and light variants. Use brightness-aware helpers: `AppTheme.cardGradientA(brightness)`, `AppTheme.topBarBg(brightness)`, `AppTheme.premiumElevation(brightness)`, etc.

3. **Do not use `Navigator.push` cross-feature.** Always `context.go()`, `context.push()`, or `context.pop()` from GoRouter.

4. **Do not pass `coupleId: null` to `EncryptionService`** in production code paths. The fallback dev key produces unreadable ciphertext in production.

5. **Do not create new `SupabaseClient` instances.** Use `Supabase.instance.client` (or `ref.watch(supabaseClientProvider)` from `lib/providers/supabase_provider.dart`).

6. **Do not add business logic to `build()` methods.** Extract to providers or services.

7. **Do not leave `forceWinkPlusForTesting = true` in release builds.** It's scoped to `kDebugMode` in `AppConstants` — confirm this before any store submission.

8. **Do not inline persona ID strings.** Always use `AppConstants.personaSassyCupid`, `AppConstants.personaChaosGremlin`, etc.

9. **Do not subscribe to Realtime channels without calling `unsubscribe()` on dispose.** Always call `BattleRealtimeService.dispose()` in the widget's `dispose()`.

10. **Do not forget `battle_status` filter on vault queries.** The vault shows active battles only; always filter `battle_status = 'active'` to exclude resolved battles from the active list.

---

## Key Docs

| File | Purpose |
|---|---|
| `PRODUCT_BLUEPRINT.md` | Game mechanics source of truth: personas, DRS formula, Wink+ rules, unlock logic |
| `docs/ARCHITECTURE.md` | Full provider graph, feature module layout, data flow patterns |
| `docs/DATABASE.md` | Schema, migration map, RLS policies, RPCs, Realtime, Edge Functions |
| `docs/PROJECT_STATE.md` | Session memory: what's implemented, what's next |
| `decision-log.md` | Why key architectural choices were made |
| `LOCAL_VALIDATION.md` | Manual smoke-test checklist for two-account testing |
| `supabase/migrations/README.md` | Migration run order + Edge Function deploy steps |
