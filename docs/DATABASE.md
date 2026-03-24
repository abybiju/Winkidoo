# Winkidoo — Database Reference

Single reference for all database concerns: schema, migrations, RLS, RPCs, Storage, Edge Functions, and Realtime. Cross-reference with `supabase/migrations/README.md` for deploy history.

---

## Migration Run Order

Migrations in `supabase/migrations/` must be run **manually** in numeric order via Supabase SQL Editor (Dashboard → SQL Editor → New query). There is no automated migration runner.

| # | File | Purpose |
|---|---|---|
| 001 | `001_initial_schema.sql` | `couples`, `surprises`, `attempts`, `winks_balance`, `transactions`; all initial RLS; `ensure_winks_balance()` trigger function |
| 002 | `002_battle_messages.sql` | `battle_messages` table; Realtime publication for `battle_messages` |
| 003 | `003_wink_plus.sql` | Adds `wink_plus_until timestamptz` to `couples` |
| 004 | `004_surprise_type_photo.sql` | Adds `surprise_type text`, `content_storage_path text` to `surprises` |
| 005 | `005_blueprint_v1_schema.sql` | Adds `battle_status`, `archived_flag`, `seeker_score`, `resistance_score`, `fatigue_level`, `last_activity_at`, `winner`, `creator_defense_count` to `surprises`; creates `treasure_archive`; creates `judges` with seed data |
| 006 | `006_surprise_resolved_at.sql` | Adds `resolved_at timestamptz` to `surprises` |
| 007 | `007_increment_creator_defense_rpc.sql` | RPC `increment_surprise_creator_defense(p_surprise_id uuid)` |
| 008 | `008_realtime_surprises.sql` | Adds `surprises` table to `supabase_realtime` publication |
| 009 | `009_user_push_tokens.sql` | Initial `user_push_tokens` table (single device per user) |
| 010a | `010_user_push_tokens_multi_device.sql` | Migrate push tokens to multi-device: `id uuid PK`, `push_token text UNIQUE` |
| 010b | `010_profiles_avatar.sql` | `profiles` table; `updated_at` trigger; `profile-avatars` Storage bucket + policies |
| 011 | `011_judges_data_driven.sql` | Extends `judges` with `tagline`, `difficulty_level`, `chaos_level`, `tone_tags`, `preview_quotes`, `primary_color_hex`, `is_premium`; backfills all 5 persona rows; drops legacy `premium_flag` |
| 012 | `012_judges_is_new.sql` | Adds `is_new bool` to `judges` (seasonal badge) |
| 013 | `013_judges_season_push_sent.sql` | Adds `season_push_sent bool` to `judges` (one-time push guard) |

**Note:** Migrations `010a` and `010b` are independent of each other but both depend on `001`. Run all files in filename order. Both `010_` files must be applied.

---

## Table Schemas

### `couples`
One row per couple. Created by `user_a` when they start a vault; `user_b` joins via invite code.

| Column | Type | Constraints |
|---|---|---|
| `id` | `uuid` | PK, default `gen_random_uuid()` |
| `user_a_id` | `uuid` | FK → `auth.users`, NOT NULL |
| `user_b_id` | `uuid` | FK → `auth.users`, nullable |
| `invite_code` | `text` | UNIQUE, NOT NULL |
| `linked_at` | `timestamptz` | nullable |
| `created_at` | `timestamptz` | default `now()` |
| `wink_plus_until` | `timestamptz` | nullable |

Dart model: `lib/models/couple.dart`
- `couple.isLinked` = `user_b_id != null && linked_at != null`
- `couple.isWinkPlus` = `wink_plus_until != null && wink_plus_until!.isAfter(DateTime.now())`

---

### `surprises`
Core game entity. Each surprise is one game round.

| Column | Type | Constraints / Default |
|---|---|---|
| `id` | `uuid` | PK |
| `couple_id` | `uuid` | FK → `couples`, NOT NULL |
| `creator_id` | `uuid` | FK → `auth.users`, NOT NULL |
| `content_encrypted` | `text` | NOT NULL |
| `unlock_method` | `text` | CHECK `('persuade','collaborate')` |
| `judge_persona` | `text` | CHECK `(5 persona IDs)` |
| `difficulty_level` | `int` | CHECK `(1-5)`, DEFAULT `2` |
| `auto_delete_at` | `timestamptz` | nullable |
| `is_unlocked` | `bool` | DEFAULT `false` |
| `unlocked_at` | `timestamptz` | nullable |
| `created_at` | `timestamptz` | default `now()` |
| `surprise_type` | `text` | DEFAULT `'text'` (`'text'`, `'photo'`, `'voice'`) |
| `content_storage_path` | `text` | nullable (Storage path for photo/voice) |
| `battle_status` | `text` | DEFAULT `'active'` CHECK `('active','resolved')` |
| `resolved_at` | `timestamptz` | nullable |
| `archived_flag` | `bool` | DEFAULT `false` |
| `seeker_score` | `int` | DEFAULT `0` |
| `resistance_score` | `int` | nullable |
| `fatigue_level` | `int` | DEFAULT `0` |
| `last_activity_at` | `timestamptz` | nullable |
| `winner` | `text` | nullable (`'seeker'` or `'creator'`) |
| `creator_defense_count` | `int` | DEFAULT `0` |

Both `surprises` and `battle_messages` are in the Supabase Realtime publication.

---

### `battle_messages`
Live judge chat history. One row per message in a battle.

| Column | Type | Constraints / Default |
|---|---|---|
| `id` | `uuid` | PK |
| `surprise_id` | `uuid` | FK → `surprises`, NOT NULL |
| `sender_type` | `text` | CHECK `('seeker','creator','judge')` |
| `sender_id` | `uuid` | FK → `auth.users`, nullable (null for judge messages) |
| `content` | `text` | NOT NULL |
| `is_verdict` | `bool` | DEFAULT `false` |
| `verdict_score` | `int` | nullable, CHECK `(0-100)` |
| `verdict_unlocked` | `bool` | nullable |
| `created_at` | `timestamptz` | default `now()` |

In Realtime publication.

---

### `attempts`
Legacy single-shot submission history. Predates live-chat battles; kept for data continuity.

| Column | Type |
|---|---|
| `id` | `uuid` PK |
| `surprise_id` | `uuid` FK |
| `user_id` | `uuid` FK |
| `content` | `text` |
| `ai_score` | `int` nullable |
| `ai_commentary` | `text` nullable |
| `created_at` | `timestamptz` |

---

### `winks_balance`
Virtual currency per user. One row per user.

| Column | Type |
|---|---|
| `user_id` | `uuid` PK FK → `auth.users` |
| `balance` | `int` CHECK `(>= 0)`, DEFAULT `0` |
| `last_updated` | `timestamptz` |

`ensure_winks_balance()` trigger function creates a row on first use.

---

### `transactions`
Winks spend/earn audit log.

| Column | Type |
|---|---|
| `id` | `uuid` PK |
| `user_id` | `uuid` FK |
| `amount` | `int` (positive = earn, negative = spend) |
| `type` | `text` |
| `description` | `text` nullable |
| `created_at` | `timestamptz` |

---

### `treasure_archive`
Metadata for battles the seeker chose to keep after reveal.

| Column | Type |
|---|---|
| `id` | `uuid` PK |
| `surprise_id` | `uuid` FK → `surprises` |
| `couple_id` | `uuid` FK → `couples` |
| `judge_persona` | `text` |
| `attempts_count` | `int` |
| `creator_interventions_count` | `int` |
| `winner` | `text` nullable |
| `final_quote` | `text` nullable |
| `archived_at` | `timestamptz` DEFAULT `now()` |
| `content_reopen_allowed` | `bool` DEFAULT `true` |

---

### `judges`
Data-driven judge persona definitions. Seeded at migration 005, extended by 011–013.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | |
| `persona_id` | `text` UNIQUE | CHECK 5 persona IDs |
| `name` | `text` | Display name |
| `accent_color_hex` | `text` nullable | |
| `avatar_asset_path` | `text` nullable | Legacy field |
| `tagline` | `text` nullable | Short persona description |
| `difficulty_level` | `int` DEFAULT `2` | 1–5 |
| `chaos_level` | `int` DEFAULT `1` | 1–5 |
| `tone_tags` | `text[]` | e.g. `['sassy','playful']` |
| `preview_quotes` | `text[]` | Sample judge dialogue |
| `primary_color_hex` | `text` nullable | Persona brand color |
| `created_at` | `timestamptz` | |
| `is_premium` | `bool` NOT NULL DEFAULT `false` | Wink+ only if true |
| `season_start` | `timestamptz` nullable | Seasonal window start |
| `season_end` | `timestamptz` nullable | Seasonal window end |
| `is_new` | `bool` nullable | Badge: "new judge" |
| `season_push_sent` | `bool` nullable | Guards one-time push |

**Active judge query:**
```sql
WHERE season_start IS NULL           -- permanent judge
   OR now() BETWEEN season_start AND season_end  -- seasonal judge in window
```

**Persona IDs** (use `AppConstants` constants in Dart — never inline strings):
- `sassy_cupid` — free, permanent
- `poetic_romantic` — free, permanent
- `chaos_gremlin` — premium, permanent
- `the_ex` — premium, permanent
- `dr_love` — premium, permanent

---

### `profiles`
Avatar persistence per user. Created on first avatar save.

| Column | Type | Notes |
|---|---|---|
| `user_id` | `uuid` PK FK → `auth.users` | |
| `avatar_mode` | `text` | CHECK `('none','preset','upload')` DEFAULT `'none'` |
| `avatar_asset_path` | `text` nullable | Preset asset path |
| `avatar_storage_path` | `text` nullable | Upload path in Storage |
| `avatar_url` | `text` nullable | Public URL for uploaded avatar |
| `created_at` | `timestamptz` | |
| `updated_at` | `timestamptz` | Maintained by trigger |

`updated_at` is auto-maintained by a DB trigger added in migration `010b`.

---

### `user_push_tokens`
FCM/APNs device tokens. Multi-device: one row per device per user.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | |
| `user_id` | `uuid` FK → `auth.users` | |
| `push_token` | `text` UNIQUE | Device token |
| `push_platform` | `text` | CHECK `('ios','android','web')` |
| `updated_at` | `timestamptz` | |

---

## RLS Policy Summary

All tables have Row Level Security enabled. Policies use `auth.uid()`.

| Table | Select | Insert | Update | Delete |
|---|---|---|---|---|
| `couples` | Own couple (`user_a_id = auth.uid()` OR `user_b_id = auth.uid()`) | Own as user_a | Own couple | — |
| `surprises` | Couple member (via `couple_id`) | Couple member | Couple member | — |
| `battle_messages` | Couple member (via `surprise_id → couple_id` join) | Couple member | — | — |
| `attempts` | Couple member (via surprise → couple join) | Own (`user_id = auth.uid()`) | — | — |
| `winks_balance` | Own (`user_id = auth.uid()`) | Own | Own | — |
| `transactions` | Own | Own | — | — |
| `treasure_archive` | Couple member (via `couple_id`) | Couple member | — | — |
| `judges` | Anyone (`USING (true)`) | — | — | — |
| `profiles` | Own (`user_id = auth.uid()`) | Own | Own | — |
| `user_push_tokens` | Own | Own | Own | — |

**Note on `battle_messages`:** Judge messages have `sender_id = null` and `sender_type = 'judge'`. The INSERT RLS on `battle_messages` only checks couple membership (the calling user is a couple member), not `sender_type`. This is intentional — the judge messages are inserted by the app on behalf of the couple.

---

## Storage Buckets

| Bucket | Public? | Path pattern | Who writes |
|---|---|---|---|
| `surprises` | No (signed URLs required) | `<user_id>/<filename>` | Any authenticated couple member |
| `profile-avatars` | Yes | `<user_id>/<filename>` | Own user only (folder = `auth.uid()`) |

**Surprises bucket usage:**
1. Upload file → get `content_storage_path`
2. Store path in `surprises.content_storage_path`
3. At reveal time, generate a signed URL via `supabase.storage.from('surprises').createSignedUrl(path, 3600)`
4. Do NOT store the signed URL — it expires. Always regenerate at display time.

See `docs/STORAGE_SETUP.md` for full bucket policy SQL.

---

## Edge Functions

### `send_battle_notification`
Location: `supabase/functions/send_battle_notification/`

**Triggers** (DB webhooks, configured in Supabase Dashboard → Database → Webhooks):
- `public.surprises` — INSERT and UPDATE events
- `public.judges` — INSERT and UPDATE events

**Behavior:**
- `surprises` INSERT → push "New surprise created" to partner's device(s)
- `surprises` UPDATE where `battle_status` changed to `'resolved'` → push "Battle resolved" to relevant users
- `judges` INSERT or UPDATE where `is_new = true` AND `season_push_sent != true` → push "New Judge Has Arrived" to all active users → sets `season_push_sent = true` (prevents re-send)

**Required Supabase secret:**
```bash
supabase secrets set FIREBASE_SERVICE_ACCOUNT='<full_json_of_service_account>'
```

See `docs/FIREBASE_AND_PUSH_SETUP.md` for full setup and deploy steps.

---

## Key RPCs

### `increment_surprise_creator_defense(p_surprise_id uuid)`

```sql
-- SECURITY INVOKER (RLS applies — caller must be a couple member)
UPDATE surprises
SET creator_defense_count = creator_defense_count + 1,
    last_activity_at = now()
WHERE id = p_surprise_id;
```

**Why RPC instead of client-side read-modify-write:** Prevents race condition when both partners are simultaneously active. The atomic UPDATE ensures no defense count is lost.

**Called from:** `BattleChatScreen` when creator sends a defense message.

```dart
await supabase.rpc('increment_surprise_creator_defense', params: {'p_surprise_id': surpriseId});
```

---

## Realtime Channels

**Tables in `supabase_realtime` publication:**
1. `battle_messages` — added in migration 002
2. `surprises` — added in migration 008

**Channel naming convention:**

| Channel name | Table | Filter | Used by |
|---|---|---|---|
| `'vault:${coupleId}'` | `surprises` | `couple_id = eq.<coupleId>` | `RealtimeSurprisesSubscription` widget |
| `'battle:${surpriseId}'` | `battle_messages` | `surprise_id = eq.<surpriseId>` | `BattleRealtimeService` |
| `'battle:${surpriseId}'` | `surprises` | `id = eq.<surpriseId>` (UPDATE only) | `BattleRealtimeService` (same channel, second subscription) |

**Important:** `BattleRealtimeService` holds one channel per instance. The service compares `_subscribedSurpriseId` to guard against re-subscribing. Always call `dispose()` in the widget's `dispose()` method to call `channel.unsubscribe()`.

---

## Adding a New Migration

1. Create `supabase/migrations/<NNN>_<description>.sql` where `<NNN>` is the next sequence number.
2. Write idempotent SQL: use `ADD COLUMN IF NOT EXISTS`, `CREATE TABLE IF NOT EXISTS`, drop-then-create for policies.
3. Update `supabase/migrations/README.md` — add the new entry with purpose description.
4. Update this file (`docs/DATABASE.md`) — add to the migration table and update the affected table schema section.
5. Update `docs/PROJECT_STATE.md` → "Migrations" section with the new entry.
6. If the migration adds or renames columns on a model-backed table (`surprises`, `couples`, `judges`, `profiles`, etc.), update the corresponding `fromJson`/`toJson` in `lib/models/`.
7. Run manually in Supabase SQL Editor (Dashboard → SQL Editor → New query → paste and run).

**Never run migrations automatically** — always review and run manually to avoid irreversible data loss in production.
