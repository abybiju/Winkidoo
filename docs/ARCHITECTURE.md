# Winkidoo — Architecture Reference

Deep reference for Claude Code when modifying or adding features. Start with `CLAUDE.md` for the quick-reference summary.

---

## Feature Module Layout

Each feature dir contains screen widgets only. No cross-feature imports.

```
lib/features/
  auth/
    welcome_auth_screen.dart       # Full-screen hero; "Get Started" → /login
    login_screen.dart              # Email + Google/Apple/Facebook OAuth
    couple_link_screen.dart        # Create vault or join with invite code
  couple/
    vault_sealed_screen.dart       # Creator waits for partner; shows invite code + share/copy
  home/
    home_screen.dart               # Avatar rail, battle hero, vault summary, judge spotlight, recent wins
  vault/
    vault_list_screen.dart         # "Waiting for You" + "Your Surprises" sections; realtime updates
    create_surprise_screen.dart    # Type selector, judge, difficulty, unlock method, content, auto-delete, lock
    wink_plus_screen.dart          # Premium upsell (coming soon paywall)
    realtime_surprises_subscription.dart  # Widget that subscribes to vault Realtime channel
  battle/
    battle_chat_screen.dart        # Live judge chat; seeker + creator + judge messages
    judge_deliberation_screen.dart # Verdict animation ("The judge deliberates...")
    reveal_screen.dart             # Decrypt content; confetti on unlock; keep/delete options
    persuasion_meter.dart          # Visual resistance/persuasion progress bar
    pre_battle_tease.dart          # Judge aura screen; 1.5s auto-advance before battle
    submission_screen.dart         # Legacy single-shot submission (pre-live-chat)
  treasure/
    treasure_archive_screen.dart   # Overview cards; blur/lock for non-Wink+
    treasure_detail_screen.dart    # Full content + chat replay + replay battle (Wink+)
  profile/
    profile_screen.dart            # Profile edit, couple stats, achievements, settings, logout
  season/
    (SeasonRecapScreen + SeasonRecapStorageService; recap on season judge end)
  onboarding/
    onboarding_screen.dart         # 3 slides: value, couple link, first surprise
  play/
    play_screen.dart               # Play tab: Daily Dare, Mini-Game, Packs, Campaigns, Judges, Character Chat
  character_chat/
    chat_rooms_screen.dart         # List of all chat rooms (couple/friend/group)
    character_chat_screen.dart     # Live chat with character selector + Gemini transform
    add_friends_screen.dart        # Join by invite code + friends list
    create_room_screen.dart        # Create 1-on-1 or group chat
    widgets/
      character_selector.dart      # Horizontal scrollable character chips
      chat_message_bubble.dart     # Message bubble with tap-to-reveal + transform shimmer
      chat_input_bar.dart          # Character selector + text input + send button
  winks/
    winks_tab_screen.dart          # Winks economy (legacy, replaced by Play tab — balance moved to Profile)
```

**Rule:** Feature screens import from `lib/providers/`, `lib/services/`, `lib/models/`, and `lib/core/`. Never import from another feature directory.

---

## Provider Dependency Graph

```
Supabase.instance.client
  └── supabaseClientProvider (Provider<SupabaseClient>)
        └── lib/providers/supabase_provider.dart

Supabase auth stream
  └── authStateProvider (StreamProvider<AuthState>)
        └── lib/providers/auth_provider.dart
              └── currentUserProvider (Provider<User?>)

coupleProvider (AsyncNotifierProvider<CoupleNotifier, Couple?>)
  └── lib/providers/couple_provider.dart
  depends on: authStateProvider (reads current user id)

effectiveWinkPlusProvider (Provider<bool>)
  └── lib/providers/couple_provider.dart
  depends on: coupleProvider + AppConstants.forceWinkPlusForTesting

surprisesListProvider (FutureProvider<List<Surprise>>)
  └── lib/providers/surprise_provider.dart
  depends on: coupleProvider (reads couple.id)

surpriseByIdProvider (FutureProvider.family<Surprise?, String>)
  └── lib/providers/surprise_provider.dart
  depends on: supabaseClientProvider

partnerAddedSurpriseAtProvider (StateProvider<DateTime?>)
  └── lib/providers/surprise_provider.dart
  set by: RealtimeSurprisesSubscription widget on INSERT

coupleStatsProvider (FutureProvider<CoupleStats>)
  └── lib/providers/couple_stats_provider.dart
  depends on: surprisesListProvider, coupleProvider
  NOTE: computed client-side — no DB query

achievementsProvider (FutureProvider<List<Achievement>>)
  └── lib/providers/achievements_provider.dart
  depends on: coupleStatsProvider
  NOTE: computed client-side — no DB table

streakProvider (FutureProvider<StreakStats>)
  └── lib/providers/streak_provider.dart
  depends on: surprisesListProvider
  NOTE: computed from resolved surprises by ISO week — no DB table

activeJudgesProvider (FutureProvider<List<Judge>>)
  └── lib/providers/judges_provider.dart
  query: season_start IS NULL OR now() BETWEEN season_start AND season_end

judgeByPersonaIdProvider (FutureProvider.family<Judge?, String>)
  └── lib/providers/judges_provider.dart

battleMessagesProvider (FutureProvider.family<List<BattleMessage>, String>)
  └── lib/providers/battle_provider.dart
  depends on: supabaseClientProvider

hasActiveBattleProvider (FutureProvider.family<bool, String>)
  └── lib/providers/battle_provider.dart
  depends on: surpriseByIdProvider

winsBalanceProvider (FutureProvider<WinksBalance?>)
  └── lib/providers/winks_provider.dart
  depends on: authStateProvider

treasureArchiveProvider (FutureProvider<List<TreasureArchive>>)
  └── lib/providers/treasure_archive_provider.dart
  depends on: coupleProvider

seasonRecapProvider (FutureProvider<SeasonRecap?>)
  └── lib/providers/season_recap_provider.dart

onboardingCompleteProvider (StateNotifierProvider<bool>)
  └── lib/providers/onboarding_provider.dart

themeModeProvider (StateProvider<ThemeMode>)
  └── lib/providers/theme_provider.dart

userAvatarProfileProvider (FutureProvider<Profile?>)
  └── lib/providers/user_profile_provider.dart
  depends on: authStateProvider

userProfileMetaProvider, isProfileCompleteProvider, missingProfileFieldsProvider
  └── lib/providers/user_profile_provider.dart
  reads user metadata from Supabase auth
```

---

## Service Layer Responsibilities

| Service | File | Responsibility | Owns Supabase calls? |
|---|---|---|---|
| `AiJudgeService` | `services/ai_judge_service.dart` | Gemini Flash API; `judgeChat()` live chat, `getHint()`. JSON parse with retry. Structured JSON schema validation. | No |
| `EncryptionService` | `services/encryption_service.dart` | AES-256 encrypt/decrypt. Key from `coupleId + 'winkidoo-v1'`. | No |
| `BattleRealtimeService` | `services/battle_realtime_service.dart` | Channel subscribe/unsubscribe for `battle_messages` + `surprises` row during a battle. One channel per `surpriseId`. | Yes (Realtime only) |
| `BattleService` | `services/battle_service.dart` | `resolveAsSeekerWin()` — single Supabase UPDATE to mark surprise resolved. | Yes |
| `PushService` | `services/push_service.dart` | FCM token upsert on login; `onTokenRefresh` listener. Multi-device: `user_push_tokens` table. | Yes |
| `RealtimeService` | `services/realtime_service.dart` | Subscribe to `surprises` by `couple_id` for vault live updates. | Yes (Realtime only) |
| `ProfileAvatarService` | `services/profile_avatar_service.dart` | Load/save profile avatar (upload or preset) to `profiles` table + `profile-avatars` Storage. | Yes |
| `AchievementStorageService` | `services/achievement_storage_service.dart` | Read/write seen achievement IDs in `shared_preferences`. | No (local only) |
| `SeasonRecapStorageService` | `services/season_recap_storage_service.dart` | Read/write seen season IDs in `shared_preferences`. | No (local only) |

---

## Navigation Flow

Full redirect state machine defined in `lib/router/app_router.dart`:

```
Launch (authLoading == true)
  → stay (null redirect)

Unauthenticated
  → '/' (WelcomeAuthScreen)
  → '/login' (LoginScreen) — allowed without redirect

Authenticated + onboarding incomplete
  → '/onboarding' (OnboardingScreen, 3 slides)

Authenticated + onboarding done + no couple
  → '/couple-link' (CoupleLinkScreen)

Authenticated + has couple + NOT linked (partner hasn't joined)
  → '/vault-sealed' (VaultSealedScreen — shows invite code)

Authenticated + has couple + linked
  → '/shell/vault' (main app)
  Note: auto-redirects away from '/', '/login', '/onboarding', '/couple-link'
        auto-redirects away from '/vault-sealed' once linked
```

**Shell tabs** (`StatefulShellRoute.indexedStack`):
```
index 0: /shell/home    → HomeScreen
index 1: /shell/vault   → RealtimeSurprisesSubscription > ResponsiveVaultShell > VaultListScreen
index 2: /shell/play    → PlayScreen
index 3: /shell/profile → ProfileScreen
```

**Off-shell routes** (use `context.push`, not `context.go`):
```
/shell/create                        → CreateSurpriseScreen
/shell/battle/:id                    → BattleChatScreen(surpriseId)
/shell/deliberation  (extra map)     → JudgeDeliberationScreen(surpriseId, judgeResponse, creatorId)
/shell/reveal/:id    (extra map)     → RevealScreen(surpriseId, judgeResponse, creatorId)
/shell/wink-plus                     → WinkPlusScreen
/shell/chat                          → ChatRoomsScreen
/shell/chat/:roomId                  → CharacterChatScreen(roomId)
/shell/chat/add-friends              → AddFriendsScreen
/shell/chat/create-room              → CreateRoomScreen
/shell/treasure-archive              → TreasureArchiveScreen
/shell/treasure-archive/:surpriseId  → TreasureDetailScreen(surpriseId)
```

**Data via `extra`:** Routes that need data (deliberation, reveal) receive a `Map<String, dynamic>` via `state.extra`. Never use global state for route-scoped parameters.

**Android back:** Double-back-to-exit handled in `_ShellScaffoldState` — shows snackbar on first press, exits on second within 2 seconds.

---

## Data Flow: Create → Battle → Reveal

End-to-end trace of the primary game loop:

1. **Create** (`CreateSurpriseScreen`): user fills form → `EncryptionService.encrypt(content, coupleId: couple.id)` → INSERT row into `surprises` with encrypted content → `ref.invalidate(surprisesListProvider)` → navigate back.

2. **Vault notification** (`RealtimeSurprisesSubscription`): Supabase Realtime fires INSERT event on `surprises` → `ref.invalidate(surprisesListProvider)` → `partnerAddedSurpriseAtProvider` set to `DateTime.now()` → snackbar shown to partner.

3. **Pre-battle** (`PreBattleTease`): seeker taps surprise card → judge aura screen → 1.5s auto-advance.

4. **Battle start** (`BattleChatScreen`): `BattleRealtimeService.subscribe('battle:$surpriseId')` opens Realtime channel for `battle_messages` + the `surprises` row.

5. **Seeker sends message**: INSERT `battle_message` (sender_type: `'seeker'`) → call `AiJudgeService.judgeChat(messages, judgePersona, difficulty)` → INSERT judge response as `battle_message` (sender_type: `'judge'`) → UPDATE `surprises.seeker_score` and `fatigue_level`.

6. **Creator defends**: call `increment_surprise_creator_defense(p_surprise_id)` RPC (atomic increment) → INSERT `battle_message` (sender_type: `'creator'`).

7. **Verdict**: when `isVerdict == true` in judge response → `context.push('/shell/deliberation', extra: {...})` → `JudgeDeliberationScreen` animation → then either `BattleService.resolveAsSeekerWin()` or battle continues.

8. **Resolution**: `resolveAsSeekerWin()` UPDATEs `surprises` row (`battle_status: 'resolved'`, `is_unlocked: true`, `winner: 'seeker'`) → Realtime UPDATE fires → `BattleRealtimeService` callback → `context.pushReplacement('/shell/reveal/$id', extra: {...})`.

9. **Reveal** (`RevealScreen`): `EncryptionService.decrypt(contentEncrypted, coupleId: couple.id)` → display content + confetti → keep in Treasure Archive or delete.

**Guard:** `_navigatedToVerdict` boolean in `BattleChatScreen` prevents duplicate navigation if Realtime fires multiple times.

---

## Responsive Layout Strategy

Breakpoint: `AppConstants.desktopBreakpoint = 700.0` (logical pixels).

`ResponsiveVaultShell` (`lib/core/layout/responsive_vault_shell.dart`) checks `kIsWeb && MediaQuery.sizeOf(context).width >= 700`:
- **Desktop (≥700px, web only):** Two-panel layout — `VaultListScreen` at 320px fixed width left panel + detail `Navigator` at `flex: 2` right panel.
- **Mobile / native (< 700px or non-web):** Single-panel `VaultListScreen` with standard navigation.

All other screens are single-panel. Do not add new breakpoints outside `AppConstants`.

---

## Theme and Design System

File: `lib/core/theme/app_theme.dart`

**Two themes:**
- `AppTheme.darkTheme` — "Midnight Romance": midnight plum background (`#0F172A` → `#1B1030`)
- `AppTheme.lightTheme` — "Blush & Wink": pastel yellow-white (`#FFF7A6` → `#FFFDF6`)

**Core brand tokens:**
- `AppTheme.primary` = `AppTheme.primaryPink` = `#E85D93`
- `AppTheme.secondary` = `AppTheme.plum` = `#6D2E8C`
- `AppTheme.accent` = `AppTheme.premiumGold` = `#F5C76B`

**Brightness-adaptive helpers** (always prefer these over hardcoded colors):
```dart
AppTheme.gradientColors(brightness)      // Background gradient (2 colors)
AppTheme.cardGradientA(brightness)       // Card gradient start
AppTheme.cardGradientB(brightness)       // Card gradient end
AppTheme.topBarBg(brightness)            // Top bar background
AppTheme.navBg(brightness)               // Bottom nav background
AppTheme.navActive(brightness)           // Active nav icon/label
AppTheme.navInactive(brightness)         // Inactive nav icon/label
AppTheme.pillBg(brightness)              // CTA pill background
AppTheme.badgeBg(brightness)             // Badge background
AppTheme.premiumElevation(brightness)    // List<BoxShadow> — 3-layer premium shadow
AppTheme.toyCardShadow(brightness)       // List<BoxShadow> — card shadow
```

**Typography:** Poppins for headings (`displayLarge`, `displayMedium`, `AppBar`). Inter for body and labels. Loaded via `google_fonts`.

**Shared widget primitives** in `lib/core/widgets/`:
- `WinkCard` — standard card surface with gradient + shadow
- `PillCta` — pill-shaped CTA button
- `AvatarChipRow` — horizontal avatar rail
- `WinkidooTopBar` — top bar with logo, streak badge, bell
- `WinkBottomNav` — bottom nav with center FAB
- `SkeletonCard` / `SkeletonMessageRow` — loading placeholders (prefer over spinners)
- `ErrorScreen` — user-friendly error with retry/back

Do not re-implement these. Do not add color literals in new screen code.

---

## Wink+ Gating Pattern

Premium features are gated via `effectiveWinkPlusProvider` (`lib/providers/couple_provider.dart`):
- In `kDebugMode`: `AppConstants.forceWinkPlusForTesting = kDebugMode` → always `true`
- In release: reads `couple.isWinkPlus` (derived from `couples.wink_plus_until > now()`)

**To add a premium gate:**
```dart
final isPlus = ref.watch(effectiveWinkPlusProvider);
if (!isPlus) {
  context.push('/shell/wink-plus'); // or show inline paywall sheet
  return;
}
```

Premium judge personas (`chaos_gremlin`, `the_ex`, `dr_love`) are gated by `judge.is_premium` from the DB, checked against `effectiveWinkPlusProvider`. Free personas are `AppConstants.freePersonas` (`sassy_cupid`, `poetic_romantic`).

**Winks economy:**
- Free tier: `AppConstants.freeAttemptsPerDay = 3` daily attempts
- Wink+: `AppConstants.winkPlusFreeAttemptsPerDay = 10` daily attempts
- Hint cost: `AppConstants.hintCostWinks = 5`
- Instant unlock cost: `AppConstants.instantUnlockCostWinks = 50`
