# Winkidoo Supabase migrations

Run these in order in the Supabase SQL Editor (Dashboard → SQL Editor → New query):

1. **001_initial_schema.sql** — `couples`, `surprises`, `attempts`, `winks_balance`, `transactions`, RLS, triggers
2. **002_battle_messages.sql** — `battle_messages` for live judge chat
3. **003_wink_plus.sql** — `wink_plus_until` on `couples`
4. **004_surprise_type_photo.sql** — `surprise_type`, `content_storage_path` on `surprises`
5. **005_blueprint_v1_schema.sql** — `battle_status`, `archived_flag`, battle state columns on `surprises`; `treasure_archive`; `judges`
6. **006_surprise_resolved_at.sql** — `resolved_at` on `surprises` for explicit battle resolution time
7. **007_increment_creator_defense_rpc.sql** — RPC `increment_surprise_creator_defense(p_surprise_id)` for atomic creator_defense_count + last_activity_at
8. **008_realtime_surprises.sql** — Add `surprises` to `supabase_realtime` publication (so battle screen can stream surprise row for resolve)
9. **009_user_push_tokens.sql** — `user_push_tokens` table for FCM/APNs device tokens (push notifications)
10. **010_user_push_tokens_multi_device.sql** — Multi-device: `id` PK, `push_token` unique (one row per device per user)
11. **011_judges_data_driven.sql** — Data-driven judges: add `tagline`, `difficulty_level`, `chaos_level`, `tone_tags`, `preview_quotes`, `primary_color_hex`, `created_at`, `is_premium`; `season_start`/`season_end` as timestamptz; backfill from app seed; drop `premium_flag`. Active judges = permanent (season null) or now() between season window.
12. **012_judges_is_new.sql** — Judges `is_new` column for "New" badge; client hides badge after 7 days (no scheduled job).
13. **013_judges_season_push_sent.sql** — Judges `season_push_sent` for one-time "New Judge Has Arrived" push when seasonal judge becomes active.

If you see `relation "public.surprises" does not exist`, run **001** first, then 002, 003, 004, 005, 006, 007, 008.

### Push notifications (Edge Function + webhook)

- Deploy the Edge Function: `supabase functions deploy send_battle_notification`.
- Set secret: `supabase secrets set FIREBASE_SERVICE_ACCOUNT='<full JSON of Firebase service account>'`.
- In Dashboard → Database → Webhooks: (1) Create a webhook on table `public.surprises`, events **INSERT** and **UPDATE**, URL `https://<PROJECT_REF>.supabase.co/functions/v1/send_battle_notification`. (2) Create a second webhook on table `public.judges`, events **INSERT** and **UPDATE**, same URL. Payload for both: include record and old_record.

*Doc sync: Feb 2026 — migrations 001–010 documented; push (009–010) and Edge Function/webhook steps match docs/FIREBASE_AND_PUSH_SETUP.md.*
