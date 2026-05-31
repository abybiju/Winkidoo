# Winkidoo – Project state (session memory)

Short reference for what’s implemented and what’s next. No secrets or keys.

---

## Implemented (as of May 2026)

### May 30, 2026 (newest) – Friends/social layer: delete, notif fix, friend system, many-friend play (migrations 048–051, NOT yet tagged)

Three-phase social rework so the app is no longer one fixed couple — anyone can have many friends and send different surprises to different friends (each surprise still strictly 1:1). Chat stays open to anyone with a chat code.

**Phase 1 (shipped).** Creator can **delete a surprise** anytime: migration `048` adds a creator-scoped DELETE RLS policy; the vault card gets a 🗑 → confirm dialog → storage cleanup + row delete (battle_messages cascade). **Notification fix**: `getSeekerId` in `send_battle_notification` returned `userB ?? userA` on a no-match (could resolve to the creator → creator got the seeker's "A Surprise Awaits"); now returns null + a guard. Edge function redeployed.

**Phase 2 (shipped).** **Friend system** UI on the existing `user_friends` backend. Migration `049`: `profiles.display_name` + `pg_trgm` + backfill, `search_users_by_name` RPC, `user_friends.requested_by`. Profile save mirrors the name into `profiles.display_name`. Friends screen (`add_friends_screen.dart`): search by name → send request, incoming requests accept/decline, named friends list, plus join-chat-by-code. New providers: `incomingFriendRequestsProvider`, `friendDirectoryProvider`.

**Phase 3 (shipped).** Couples become **per-friend-pair containers** (a user may be in many couples). Decryption/rewards now key on `surprise.coupleId` (not the active couple) — critical for multi-couple correctness. Migrations `050` (dedupe + unique pair index + `friendship_id` + backfill user_friends) and `051` (trigger auto-creates the couple on friend-accept; `join_couple_by_code` drops the single-couple gate). Redirect no longer forces `/couple-link`. Home **avatar rail shows real friends** (`friendPairsProvider`) + Invite tile; tapping a friend creates a surprise for that pair. `surprisesListProvider` aggregates across all the user's couples. New: `couplesListProvider`, `friendPairsProvider`, `FriendPair`.

**Known follow-ups:** vault realtime still watches only the legacy couple channel (other friends' surprises appear on refresh, not live); preset (non-uploaded) friend avatars show a colored initial in the rail; the generic + create button picks the only/most-recent couple when multiple friends exist (per-friend tap is exact). **Run migrations 048→051 in order; 050 before 051.**

### May 30, 2026 (latest) – Battle judge fixes + WhatsApp-style character chat (tag v0.2.3)

**Custom judge persona was ignored in battles.** `surprises.custom_judge_id` was saved on create but never read back (no field on the `Surprise` model), and `judgeChat` received `persona: 'custom'` with no override → it fell back to the default Sassy Cupid voice ("darling/love/honey"). Fixed: `Surprise` now parses `custom_judge_id`, `CustomJudgeService.getJudgeById` loads the judge, and `battle_chat_screen` passes `personaPromptOverride` + `howToImpressOverride` so the custom judge speaks in-character. The judge **opening message** loads the same override.

**Unlock verdict never opened the reveal ("unlocked but never left the chat").** The judge JSON parser required BOTH `score` and `is_unlocked` keys, but the model often declares an unlock with only one. `hasVerdict` now triggers on either key, so the battle resolves (`battle_status → resolved`) and navigates to `/shell/reveal/:id`.

**Judge now opens first + tighter, in-persona replies.** On entering a battle the seeker gets a one-time in-persona opener (`AiJudgeService.generateBattleOpening` + `_ensureOpeningMessage`, seeker-only, skipped if anyone already spoke) that greets them and states expectations. Replies are now 1–2 short sentences and must NOT summarize/quote/repeat the seeker's message. When asked "what do you want", the judge answers directly.

**Anti-paste.** Battle input disables the copy/paste/select-all menu (`contextMenuBuilder` → empty), and the judge applies a real negative score penalty + refuses to unlock on web/quote/essay-sounding content (was a soft nudge).

**Migration `047_surprises_judge_persona_dynamic.sql`.** Dropped the hard-coded `surprises_judge_persona_check` (5-persona enum from 001) that rejected judge-pack + `custom` personas with a 23514 check-constraint violation when hiding a surprise.

**WhatsApp-style character chat.** Top bar shows the chat title centered (group name for groups, the other person's real name for 1:1); the persona/tone picker is a small "as &lt;persona&gt; · &lt;tone&gt;" line under the title, visible only to the local user. Message bubbles now show the **sender's real name** to receivers (resolved from `roomMembersProvider`), never the persona or tone — the `as <persona> <tone>` label appears only on the sender's own bubbles. Files: `character_chat_screen.dart`, `widgets/chat_message_bubble.dart`.

Released as tag **`v0.2.3`** (pubspec `0.2.3+5`).

### May 30, 2026 (later) – Storage RLS fix, image cropping, notification bell + profile gear (tag v0.2.2)

**Surprises storage bucket RLS fix.** Photo/voice surprise uploads failed with `StorageException(... new row violates row-level security policy, statusCode: 403)`. Root cause: the `surprises` Storage bucket had RLS enabled on `storage.objects` but **zero policies** (only `judge-avatars`/`profile-avatars` had policies — the surprises ones were never captured in a migration). Text surprises worked because they don't touch Storage. Fixed by **migration `046_surprises_bucket_rls.sql`**: creates the bucket + insert/select/update/delete policies scoped to couple members (folder = `<couple_id>`, checked against `couples.user_a_id`/`user_b_id`). Also corrected `docs/DATABASE.md` which wrongly documented the surprise path as `<user_id>/` (code uses `<couple_id>/`). To diagnose RLS like a "console", use Supabase Dashboard → Logs (API/Postgres) and `select … from pg_policies where tablename='objects'`.

**Image cropping on all photo uploads.** Added `image_cropper: ^9.1.0` + shared helper `lib/core/utils/image_crop_helper.dart` (`ImageCropHelper.cropOrOriginal`). Wired into all six pick sites: surprise photo, dare photo (**free-form**), and custom-judge avatar (create + my-judges), profile avatar (profile + completion sheet) (**1:1 square lock**). Helper no-ops (returns original bytes) on macOS/desktop where the plugin is unimplemented, and on crop-cancel. Registered `UCropActivity` in `AndroidManifest.xml`. Platform support: Android/iOS/Web only (square lock is best-effort on web).

**Notification bell now works on every tab.** `WinkidooTopBar.onNotificationTap` was only wired on Home and Play; Vault showed the badge but had no tap handler, and Profile used a `const` bar with neither. Added `onNotificationTap → /shell/notifications` + the unread `notificationCount` to Vault and Profile, so all four tabs behave identically.

**Profile edit moved behind a settings gear.** The inline `_GameProfileCard` (name/age/gender/avatar editor) was removed from the Profile body and is now opened from a `_EditProfileGearButton` (⚙️) in the Profile top bar as a bottom sheet (`_EditProfileSheet`). The gear shows a small pink dot when `missingProfileFieldsProvider` is non-empty so the completion nudge isn't lost. (Known minor: the dot may not clear live after saving until auth metadata refreshes.)

Released as tag **`v0.2.2`** (pubspec `0.2.2+4`).

### May 30, 2026 – Friends repositioning, server-side AI keys, cloud builds + Firebase distribution, judge/chat fix

**Friends-inclusive copy reposition.** ~60 user-facing strings across 28 files reworded from "couples/partner" to friends-forward (still inclusive — romance kept as an option, e.g. the "Romantic" judge mood). Onboarding redesigned to 3 broadened slides (surprises + AI personas/games + linking). Renames: Love Quest→Duo Quest, Couple Wrapped→Duo Wrapped, #CoupleWrapped→#DuoWrapped, "Partner code"→"Friend code". AI-judge prompts softened ("a romantic couples game"→"a playful game between friends"; generated dare/game text "your partner"→"your friend"). **Code identifiers (`couples` table, `coupleProvider`, etc.) intentionally unchanged.**

**AI provider keys moved server-side (security).** `GEMINI_API_KEY` and `TAVILY_API_KEY` no longer ship in the APK — both proxied via Edge Functions:
- `gemini-proxy` — client routes the `google_generative_ai` SDK through it (`lib/services/gemini_proxy_client.dart`, custom `httpClient`). JWT-gated + `check_rate_limit`.
- `tavily-proxy` — `lib/services/tavily_search_service.dart` calls it via `functions.invoke`.
- Keys are Supabase secrets (`supabase secrets set GEMINI_API_KEY=… / TAVILY_API_KEY=…`; helpers `set_gemini_secret.sh` / `set_tavily_secret.sh`). Verified neither key is in the built APK.

**Judge & character-chat "stuck/truncated" fix.** `gemini-2.5-flash` is a thinking model and spends hundreds of output tokens on internal reasoning (measured ~979/1024 on one call), starving `maxOutputTokens` → empty JSON (judge fell back to "One sec…") or truncated text (chat personas cut off mid-sentence). Fixed in `gemini-proxy`: it injects `generationConfig.thinkingConfig.thinkingBudget = 0` into every request. Server-side → fixes all Gemini calls (judge, chat, dares, games, personas) without an app release.

**Cloud APK builds + Firebase App Distribution.** `.github/workflows/build-smoke-test-apk.yml` builds signed APKs on GitHub Actions (no local memory use) and auto-distributes to the Firebase `testers` group. Release to testers by pushing a tag: `git tag v0.2.1 && git push origin v0.2.1`. Build number auto-bumps to the run number. Firebase app `1:356170729561:android:5cecd367b13b50faac4948`.

### May 29, 2026 – In-app account deletion (Play Store requirement)

**Edge Function `delete-account`** (`supabase/functions/delete-account/`):
- Authenticates the caller from their JWT (never trusts a client-supplied id).
- Deletes the Supabase auth user via service-role key; `ON DELETE CASCADE` wipes all user-keyed rows (profile, push tokens, winks, notifications, chat, friends, dares, etc.).
- **Preserves partner's shared vault**: if the leaving user is the couple creator and a partner exists, transfers couple ownership to the partner (`user_a_id = partner`, `user_b_id = null`) and reassigns the leaving user's `surprises`/`quests` to the partner before deletion. Partner (user_b) deletion just detaches. Solo deletion cascades the couple.
- Handles `quests.creator_id` (no cascade) by reassigning/deleting before auth user delete, so deletion can't be blocked.
- Best-effort storage cleanup of `profile-avatars/<uid>` and `judge-avatars/<uid>`; surprise media (keyed by coupleId) is intentionally preserved with the couple.
- Deploy: `supabase functions deploy delete-account --use-api`.

**Client:**
- `AccountDeletionService` (`lib/services/`): invokes the Edge Function, surfaces errors via `AccountDeletionException`, signs out locally on success.
- Profile → Settings → **Delete account** (red tile): opens a confirmation dialog requiring the user to type DELETE, shows a blocking spinner, routes to `/` on success.
- Deletion pages live at https://winkidoo.com/delete-account and /delete-data (gh-pages).

### May 26, 2026 – Character chat UI redesign (Option B inline pill)

**Layout overhaul** based on Claude Design handoff (Option B — Inline Pill):
- **Persona pill header**: Character selection moved from bottom scroll row to a centered header pill showing `[avatar] [name] [mood]`. Tap to open dropdown popover with persona grid + "+" create button.
- **Popover dropdown**: Animated fade-up popover with horizontal scrollable persona cards (avatar circle + name). Tap card to switch, tap outside to close.
- **Persona colors**: Each built-in character has a unique accent color (Trump=gold, Shakespeare=purple, Pirate=mint, etc.) that tints the header pill, composer border, send button, and mood chips.
- **Composer**: Persona-tinted border/glow, dynamic placeholder "say it as {persona}...", gradient send button.
- **Mood rail**: Sole control above text input; active chips tint with persona color instead of their own color.
- `CharacterPreset` model: added optional `color` field.
- `CharacterSelector` widget no longer used in input bar (superseded by header pill).

### May 26, 2026 – Unified Marketplace with Judges + Chat Personas tabs

**`use_for` tagging system** for custom judges:
- Migration 045: `use_for` column on `custom_judges` (`battle`/`chat`/`both`, default `both`).
- "Created for" selector in creation flow: 3 chips (Battles/Chat/Both). Defaults to "Chat" when opened from chat popover, "Both" otherwise.
- Dynamic labels: title says "Create Your Character" for chat, "Create Your Judge" for battle.
- **Marketplace screen**: Renamed from "Judge Marketplace" to "Marketplace". Two tabs — "Judges" (battle+both) and "Chat Personas" (chat+both). Shared search bar, per-tab trending + all sections.
- **Chat filtering**: `availableCharactersProvider` only shows chat/both characters.
- **Battle filtering**: `availableCustomJudgesProvider` only shows battle/both judges.
- Profile label updated to "Marketplace — Browse judges & chat personas".

### May 25, 2026 – Tone/mood modes for character chat

**9 tone overlays** that transform message style independently of character selection:
- Romantic 💕, Flirty 😘, Funny 😂, Angry 😤, Happy 😊, Savage 🔥, Dramatic 🎭, Poetic 🌹, Sarcastic 😏
- Tones combine with characters (e.g. Trump + Romantic) or work standalone (Normal + Flirty)
- `TonePreset` model + built-in tones constant in `CharacterChatService`
- `ToneSelector` widget: horizontal scrollable chips with per-tone accent colors, tap-to-toggle deselect
- Updated `transformAsCharacter()` prompt: conditional character voice + tone overlay sections
- `ChatMessageBubble`: shows tone badge ("as Trump 💕 Romantic"), tone-aware transforming indicator
- "+" Create button in `CharacterSelector` links to existing custom judge creation (`/shell/create-judge`)
- `selectedToneProvider` (StateProvider) in character_chat_provider
- Migration 044: `tone_id` column on `character_chat_messages`

### May 25, 2026 – Play tab stacked card deck redesign

**Layout overhaul:** Replaced scrollable column with 6 section headers with a stacked card deck UI.
- **PlayHeader** widget: "pick a card." with gradient-colored "card." text, "THE PLAY FLOOR" overline.
- **BattlePassBar** widget: season progress bar with points/tier display, gradient fill, tap → `/shell/battle-pass`.
- **PlayCardStack** widget: 6 cards in an overlapping deck. Active card fully expanded, others collapsed as `PeekStrip` (icon + label + accent color). `AnimatedSwitcher` with fade+size transition on card switch.
- **PeekStrip** widget: glass container with per-card accent tint, colored icon circle, label, chevron.
- **PlayCardMeta** model + `activePlayCardProvider` (StateProvider<int>) for active card state.
- Each card retains its original widget (DailyDareCard, MiniGameCard, PackBannerCard, CampaignBannerCard, JudgeSpotlightCard, CharacterChatCard) — no content changes.
- All tap handlers, bottom sheets, and navigation preserved.

### May 24, 2026 – Real-time in-app notification center

**Database:** Migration 043 — `notifications` table (user_id, type, title, body, data JSONB, is_read, created_at). RLS select+update own rows. Added to Realtime publication.

**Client-side:**
- `AppNotification` model + `NotificationType` enum (surprise_new, battle_update, dare, dare_result, mini_game, mini_game_result, campaign, custom_judge_ready, season_launch).
- `NotificationRealtimeService` — subscribes to notifications table filtered by user_id for live INSERT/UPDATE events.
- `notificationsListProvider` (FutureProvider), `unreadNotificationCountProvider` (derived count), `notificationsNotifierProvider` (markAsRead, markAllAsRead).
- `RealtimeNotificationsSubscription` widget wraps `_ShellScaffold` in router — active on all 4 tabs.
- `NotificationScreen` — full notification list with per-type icons/colors, relative timestamps, unread dot indicator, mark-all-read, pull-to-refresh.
- `NotificationRouter` — shared navigation logic extracted from `app.dart` `_navigateFromPush`, used by both push tap-to-open and notification screen tap.
- Top bar bell icon now shows real unread count across Home, Vault, and Play screens. Tap opens `/shell/notifications`.
- Foreground push handler (`FirebaseMessaging.onMessage`) shows SnackBar + invalidates notification provider for instant badge update.

**Edge Function:** `insertNotificationRows()` helper writes to `notifications` table alongside FCM push sends for all event types (surprises, dares, mini-games, campaigns, custom judges, season launches).

### May 8, 2026 – Input validation & sanitization

**Centralized InputValidator service (`lib/services/input_validator.dart`):**
- **Text sanitization:** Strips control characters, enforces max length per input type (names 50, messages 2000, surprises 5000, judge names 60, search queries 100, invite codes 12).
- **Prompt injection protection:** `sanitizeForPrompt()` strips backtick code blocks, HTML tags, and JSON-key patterns before embedding user text in Gemini AI prompts.
- **File upload validation:** 5MB image / 10MB audio size limits, extension whitelists (JPG/PNG/WebP for images, M4A/AAC/MP3/WAV for audio), magic byte header verification for images.
- **Strict type validation:** Invite codes (alphanumeric only), ages (13–120 int), names (no `<>{}\/` chars), gender (enum whitelist).

**Integration across all user entry points:**
- AI Judge Service: all 6 prompt-building methods sanitize user text before Gemini calls (battle chat, submissions, custom persona, character chat, forensics, future letter).
- Battle chat, submission, couple link, profile completion, surprise creation, custom judge creation, friend search — all wired to InputValidator.

### May 8, 2026 – Abuse protection & rate limiting

**Client-side rate limiting (ApiRateLimiter):**
- New unified `ApiRateLimiter` service — configurable per-action buckets with sliding windows and burst detection.
- **AI generation limits:** Battle chat (20/5min), character chat (30/5min), dare grading (10/10min), custom judge creation (3/hr), forensics (3/hr), future letter (5/30min), judge audition (10/10min).
- **API endpoint limits:** Friend search (15/5min), friend requests (10/10min), couple joining (5/15min), surprise creation (10/10min).
- **Burst detection:** Blocks rapid-fire calls (5+ within 500ms) with suspicious activity logging.
- All rate limit denials automatically logged via `SecurityLogger.rateLimited()`.

**Server-side rate limiting (Migration 042):**
- New `rate_limit_entries` table with user/action/timestamp tracking.
- `check_rate_limit` RPC — atomic check-and-record with configurable max attempts and window seconds.
- `cleanup_rate_limit_entries()` function for periodic purge of entries older than 24 hours.
- RLS policies: users can only insert/read their own entries.

**Integration points:** BattleChatScreen, SubmissionScreen, CharacterChatScreen, FutureLetterRevealScreen, CustomJudgeAuditionSheet, CreateCustomJudgeScreen, CreateSurpriseScreen, CoupleLinkScreen, FriendService, DailyDareProvider.

### May 8, 2026 – Full security hardening (auth + IDOR)

**Authentication hardening:**
- **Client-side rate limiting:** New `AuthRateLimiter` service — login (5/15min), signup (3/30min), password reset (3/hr) per email. Bypassed in debug mode.
- **Stronger password policy:** New `PasswordValidator` — 8+ chars, uppercase, lowercase, number required on signup.
- **Email verification enforcement:** Login now checks `emailConfirmedAt` — signs out and blocks unverified users client-side (defense-in-depth; Supabase "Confirm email" is also ON).
- **SHA-256 encryption keys:** `EncryptionService` key derivation upgraded from naive concat+zero-pad to SHA-256. Backward-compatible decryption falls back to legacy key for existing data.
- **Supabase dashboard verified:** Rate limits configured (30 signins/5min per IP, 2 emails/hr), refresh token replay detection ON (10s), email confirmation ON. CAPTCHA toggled but NOT saved (needs Flutter hCaptcha integration first). Sessions config locked behind Pro Plan.

**Secure deployment configuration:**
- **HTTPS enforced:** Android `network_security_config.xml` blocks cleartext; `usesCleartextTraffic=false`. iOS ATS enabled by default (no exceptions).
- **R8 code obfuscation:** Release builds now minify + shrink resources with ProGuard rules for Flutter/Supabase/Firebase.
- **Security event logging:** New `SecurityLogger` service + migration 041 (`security_logs` table). Logs auth success/failure, rate-limit hits, API errors. Emails masked in logs. Write-only from client (service role reads for monitoring).
- **Secrets verified:** All via `--dart-define`, no hardcoded keys. Firebase configs in `.gitignore`. Signing keys not tracked.

**IDOR prevention (ownership enforcement):**
- **Migration 040:** Secure `join_couple_by_code` RPC — validates code exists, slot open, not own code, not already in a couple, race-condition safe with `WHERE user_b_id IS NULL`.
- **Custom judge mutations:** `deleteJudge`, `publishJudgeUnique`, `unpublishJudge` now require and verify `coupleId` before any write (defense-in-depth over RLS).
- **Friend service:** `acceptFriendRequest` and `removeFriend` now filter by current `user_id` alongside friendship ID.
- **Character chat judges query:** Scoped to couple's own judges + published marketplace judges (was unfiltered top 20).
- **Full IDOR audit:** All 80+ Supabase queries verified — RLS policies solid across all 20+ tables.

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
- 031: judge-avatars storage bucket with RLS (dedicated bucket for custom judge photos).
- 032: character_chat_rooms + character_chat_members + character_chat_messages + user_friends (AI Character Chat + Friends system).
- 033: Fix chat RLS circular reference (partial).
- 034: Drop all self-referential members policies; RPCs: get_chat_room_members, join_chat_room_by_code, remove_chat_room_member.
- 035: roulette_result column on surprises (Surprise Roulette).
- 036: future_letter_judge_persona + surprise_type 'future_letter' (Love Letters from the Future).
- 037: phantom_events table + had_phantom on surprises (Phantom Judge Takeover).
- 038: forensics_reports table (Emotional Forensics).
- 039: revenuecat_events audit table (RevenueCat webhook lifecycle tracking).
- 043: notifications (in-app notification center with Realtime).
- 044: tone_id on character_chat_messages (chat tone/mood modes).
- 045: use_for on custom_judges (battle/chat/both marketplace tab filtering).

### April 2, 2026 — RevenueCat IAP / Wink+ Monetization
- **RevenueCat SDK** (`purchases_flutter ^8.1.0`): Full IAP integration for Wink+ subscriptions.
- **RevenueCatService** (`lib/services/revenuecat_service.dart`): Init SDK, configure user, fetch offerings, purchase, restore, real-time entitlement listener, auto-sync `wink_plus_until` to Supabase.
- **Subscription providers** (`lib/providers/subscription_provider.dart`): `rcEntitlementProvider` (stream of entitlement status), `rcOfferingsProvider` (pricing), `purchaseNotifierProvider` (purchase state machine).
- **effectiveWinkPlusProvider** updated: checks RevenueCat entitlement OR DB `wink_plus_until` OR debug override.
- **WinkPlusScreen rebuilt as paywall**: shows benefits, real product pricing from RevenueCat, monthly/yearly toggle with radio selection, purchase button with loading state, restore purchases link, success/error feedback, legal disclaimer.
- **Profile settings**: "Restore purchases" option added to `_SettingsCard`.
- **main.dart**: `RevenueCatService.init()` called after Supabase init; user configured on auth state change in `app.dart`.
- **Edge Function** (`supabase/functions/revenuecat-webhook/`): Receives RevenueCat webhook events, logs to `revenuecat_events`, updates `couples.wink_plus_until` for purchase/renewal/expiration.
- **Migration 039**: `revenuecat_events` audit table with service_role-only RLS.
- **Environment**: `REVENUECAT_API_KEY` via `--dart-define`, `REVENUECAT_WEBHOOK_SECRET` as Supabase secret.
- **Graceful degradation**: If no API key provided, SDK skips init; paywall shows informational message; all existing functionality unchanged.

### March 31, 2026 — UX overhaul + AI Character Chat
- **Home screen simplified**: removed Daily Dare, Mini-Game, Battle Packs, Campaigns, Judge Spotlight cards. Home now shows only: Hero avatar rail, Start a Battle CTA, Quest progress, Recent Wins.
- **Play tab replaces Winks**: new bottom nav tab (game controller icon, index 2, route `/shell/play`). Houses all activity cards moved from Home: Daily Dare, Mini-Game, Battle Packs, Campaigns, Judge Spotlight, plus new Character Chat entry.
- **Winks balance → Profile**: compact card with balance display added above subscription card in Profile screen.
- **AI Character Chat** (new feature — UI complete, RLS needs fix):
  - 4 screens: ChatRoomsScreen, CharacterChatScreen, AddFriendsScreen, CreateRoomScreen
  - 8 built-in character presets: Normal, Trump, Shakespeare, Pirate, Valley Girl, Corporate, Yoda, Gordon Ramsay
  - Custom judges also selectable as chat characters
  - Gemini `_textModel` (plain text, no JSON) for message transformation
  - Optimistic send: message appears immediately, Gemini transforms in background
  - Tap-to-reveal: see original vs transformed text on own messages
  - Friend system with invite codes and friend requests
  - Group chat support (1-on-1 + 3+ members)
  - Supabase Realtime on `character_chat_messages` for live updates
  - **RLS FIXED** (April 2): migrations 033+034 dropped all self-referential policies; cross-member ops via SECURITY DEFINER RPCs
- **Bug fixes**: judge quote font changed from Caveat to Inter for readability; avatar loading glitch fixed with SizedBox.expand + loadingBuilder

### April 2, 2026 — Character Chat RLS fix + 4 new engagement features
- **Character Chat RLS fix** (migrations 033-034): Dropped self-referential policies causing infinite recursion. Cross-member queries now use SECURITY DEFINER RPCs. Solo room creation + invite code sharing via share_plus.
- **Surprise Roulette** (migration 035): Toggle "Roulette" on create screen → partner spins a wheel before battle. 5 segments: Easy (30%), Medium (30%), Hard (25%), Chaos Mode (10%), Golden Hour (5%). Chaos = Hard + max temp judge. Golden = Easy + 2x fatigue decay + 3x XP. Custom roulette wheel widget with spring physics.
- **Love Letters from the Future** (migration 036): New `future_letter` surprise type. Creator writes a message + picks delivery date + judge persona. On delivery, Gemini rewrites the letter in the judge's voice aged 20 years. Split-view reveal screen (original + aged rewrite). Route: `/shell/future-letter/:id`.
- **Phantom Judge Takeover** (migration 037): ~8% chance per battle a rogue ghost judge hijacks for 2 exchanges. 5 phantom personas: Judge Glitch, The Time Traveler, The Drunk Poet, The Interrogator, The Hype Beast. Glitch overlay animation. Random resistance delta (-20 to +25). `had_phantom` tracked on surprise. `phantom_events` table for history.
- **Emotional Forensics** (migration 038): "View Forensics" button on reveal screen. AI analyzes battle transcript for Communication DNA (logical/emotional/humorous/poetic %), Hidden Signals (3 observations), Growth Edge, Superpower badge. `forensics_reports` table. Route: `/shell/forensics/:id`.

### March 30, 2026 — Bug fixes + Push notifications expansion
- **Bug fixes**: judge delete working, avatar upload 403 fixed (new judge-avatars bucket), avatar upload surviving gallery picker unmount, battlefield carousel remove refreshing providers, carousel avatar blink fixed (cached signed URL futures), Gemini maxOutputTokens increased to 4096 with truncated JSON repair, marketplace showing avatar photos
- **Push Notifications**: Extended Edge Function with 8 new notification types — daily dares (new/submitted/graded), mini-games (new/played/graded), campaign started, custom judge ready. Added 4 new Database Webhooks. App deep link handler routes all new types to correct screens.
- **Edge Function deploy**: Use `supabase functions deploy send_battle_notification --use-api` (bypasses Docker file sharing issue)

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

### April 4, 2026 — Android Launch Prep

- **`store/` directory created** — all Play Store assets live here.
- **Privacy Policy** (`store/privacy_policy.md`): Full Play Store-compliant policy covering Supabase, Firebase, RevenueCat, Google Gemini API, OAuth providers, E2E encryption disclosure, data retention, GDPR rights, children's policy (17+). Needs hosting at `https://winkidoo.app/privacy`.
- **Store Listing copy** (`store/store_listing.md`): App name, short description (80 chars), full keyword-optimised description, First Release "What's New" notes, Data Safety form table, and graphics requirements checklist.
- **Play Store feature graphic** (1024×500): Generated dark nebula background with neon-orange Winkidoo wordmark and golden locked-envelope icon. Needs crop to exact 1024×500 from the generated square.
- **Showcase cards** (4 generated): Judge Selection, Battle Chat, Reveal/Unlock, Create Surprise — AI-illustrated phone mockup cards with headlines and subtitles. Real app screenshots pending for final production cards.
- **`android/app/build.gradle.kts`**: Full release signing config wired — reads `android/key.properties` at build time; falls back to debug signing if file absent (local dev friendly). Keystore file itself not yet created.
- **`android/app/src/main/AndroidManifest.xml`**: Capitalised app label to `"Winkidoo"`; added `INTERNET` and `POST_NOTIFICATIONS` (Android 13+ FCM) permissions.
- **`.gitignore`**: Added `android/key.properties` and `android/upload-keystore.jks` guards.

**Remaining Android launch blockers (in order):**
1. Create Google Play Developer account ($25 at play.google.com/console)
2. Host privacy policy publicly (URL required before Play Console submission)
3. Generate release keystore (`keytool` command in `store/android_launch_checklist.md` Phase 3)
4. Export 512×512 app icon PNG from `assets/images/winkidoo new logo.png`
5. Crop feature graphic to 1024×500 px
6. Take real app screenshots → polish into showcase cards
7. Create `winkplus_monthly` + `winkplus_yearly` products in Play Console
8. Run `flutter build appbundle --release` and upload to Internal Testing

---

## Next / optional

- **Android launch** — see blockers list above; Google Play account is the immediate gate.
- Configure RevenueCat dashboard: create project, add Google Play app, create `wink_plus` entitlement, `default` offering with monthly/yearly packages.
- Deploy `revenuecat-webhook` Edge Function and set `REVENUECAT_WEBHOOK_SECRET` in Supabase secrets.
- Test full RevenueCat purchase flow on physical Android device (sandbox account).
- Test Character Chat end-to-end with two accounts (invite code join + realtime messages).
- Onboarding polish (guided first experience, welcome gift, first surprise prompt).
- Test push notifications end-to-end with two accounts.
- AI Love Coach (opt-in relationship insights from surprise patterns).

---

## Docs

- **README.md** – Setup, env (SUPABASE_URL, SUPABASE_ANON_KEY, GEMINI_API_KEY via --dart-define), structure, development log.
- **supabase/migrations/README.md** – Migration list and webhook steps.
- **docs/FIREBASE_AND_PUSH_SETUP.md** – Firebase project, configs, Edge Function deploy, secrets, webhooks (surprises + judges).
- **docs/STORAGE_SETUP.md** – Storage bucket and policies.
- **docs/OAUTH_AND_STORE_SETUP.md** – OAuth and store (no secrets in repo).
- **decision-log.md** – Architecture and product decisions.
