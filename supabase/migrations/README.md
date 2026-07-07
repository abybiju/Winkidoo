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
14. **014_quests_and_time_capsule.sql** — `quests` table + `quest_id`, `quest_step`, `unlock_after` on `surprises`; Love Quests feature.
15. **015_daily_activity_log.sql** — `daily_activity_log` table for daily streak tracking.
16. **016_couple_xp.sql** — `couple_xp` table (total_xp, current_level) for Love Levels feature; RLS couple members.
17. **017_judge_memory.sql** — `judge_memory` table for persistent AI judge personality across battles; RLS couple members.
18. **018_battle_pass.sql** — `battle_pass_seasons` + `battle_pass_progress` tables; seeds "Season 1: First Sparks"; Bronze/Silver/Gold tiers.
19. **019_referrals.sql** — `referrals` table for couple referral system (+50 Winks reward on first battle).
20. **020_collaborative_vault.sql** — Adds `is_collaborative`, `collab_partner_piece_encrypted`, `collab_partner_status` to `surprises`.
21. **021_collectibles.sql** — `judge_collectibles` table; rarity: common/rare/legendary based on seeker_score; RLS couple members.
22. **022_leaderboard.sql** — Public read policy on `couple_xp` to power anonymous global leaderboard.

23. **023_daily_dares.sql** — `daily_dares` table for Daily Love Dares feature
24. **024_themed_packs.sql** — `judge_packs`, `judge_pack_judges`, `pack_dare_templates`, `couple_active_pack`
25. **025_mini_games.sql** — `mini_game_types`, `daily_mini_games`, `pack_mini_game_templates`
26. **026_campaigns.sql** — `campaigns`, `campaign_chapters`, `couple_campaign_progress`, `campaign_rewards`
27. **027_content_expansion.sql** — Seed data: 3 new campaigns + 3 themed packs
28. **028_custom_judges.sql** — `custom_judges` + `custom_judge_uses` for Custom AI Judge Creator + Marketplace
29. **029_custom_judge_search.sql** — `status` + `notification_text` columns on `custom_judges`
30. **030_custom_judge_battlefield.sql** — `is_active_for_battle` column on `custom_judges`
31. **031_judge_avatars_bucket.sql** — `judge-avatars` storage bucket with RLS policies
32. **032_character_chat.sql** — `character_chat_rooms`, `character_chat_members`, `character_chat_messages`, `user_friends`; RLS; Realtime on messages
33. **033_fix_chat_rls_circular.sql** — Fix circular RLS policies on chat rooms/members (partial — still had self-referential co-members policy)
34. **034_fix_chat_rls_recursion_v2.sql** — Drop ALL self-referential policies on character_chat_members; add RPCs: `get_chat_room_members`, `remove_chat_room_member`, `join_chat_room_by_code`
35. **035_surprise_roulette.sql** — `roulette_result` column on surprises for Surprise Roulette feature
36. **036_future_letter.sql** — `future_letter_judge_persona` column + `surprise_type` check update for Love Letters from the Future
37. **037_phantom_judge.sql** — `phantom_events` table + `had_phantom` on surprises for Phantom Judge Takeover
38. **038_forensics.sql** — `forensics_reports` table for Emotional Forensics post-battle analysis
39. **039_revenuecat_webhook_log.sql** — `revenuecat_events` audit table for RevenueCat webhook events (subscription lifecycle tracking)
40. **040_join_couple_by_code_rpc.sql** — Secure `join_couple_by_code` RPC: validates code exists, slot open, not own code, not already in couple, race-condition guard (`WHERE user_b_id IS NULL`)
41. **041_security_logs.sql** — `security_logs` table for auth/API monitoring; RLS insert-only from client, indexed by event_type + user_id
42. **042_rate_limits.sql** — `rate_limit_entries` table + `check_rate_limit(user_id, action, max_attempts, window_seconds)` RPC for server-side sliding-window rate limiting; `cleanup_rate_limit_entries()` for periodic purge; RLS scoped to own entries
43. **043_notifications.sql** — `notifications` table for in-app notification center; indexed by `(user_id, is_read, created_at DESC)`; RLS select+update own rows; added to Realtime publication
44. **044_chat_tone_mode.sql** — Add `tone_id` column to `character_chat_messages` for mood/tone transformation overlay
45. **045_judge_use_for.sql** — Add `use_for` column (`battle`/`chat`/`both`) to `custom_judges` for marketplace tab filtering
46. **046_surprises_bucket_rls.sql** — Create `surprises` storage bucket + RLS policies (insert/select/update/delete) scoped to couple members. Fixes 403 `new row violates row-level security policy` on photo/voice surprise upload — the bucket previously had RLS enabled with no policies.
47. **047_surprises_judge_persona_dynamic.sql** — Drop the hard-coded `surprises_judge_persona_check`. The static 5-persona enum (from 001) rejected judge-pack personas (024/027) and `'custom'` judges, throwing 23514 `violates check constraint "surprises_judge_persona_check"` when hiding a surprise with any non-original judge. Personas are now a dynamic set; validation lives in the app + judges tables.
48. **048_surprises_delete_policy.sql** — Add a DELETE RLS policy on `surprises` scoped to the creator (`creator_id = auth.uid()`). The table had no delete policy, so the new "delete surprise" action was blocked. battle_messages cascade; storage objects are removed client-side first.
49. **049_profiles_identity_and_search.sql** — Friend-system search foundation: `profiles.display_name` + `pg_trgm` index + backfill from auth metadata; `search_users_by_name(p_query)` security-definer RPC; `user_friends.requested_by` to distinguish incoming vs outgoing requests.
50. **050_friend_pairs.sql** — Make `couples` a per-friend-pair container: dedupe duplicate couple rows, add unique index on the unordered member pair (linked only), `couples.friendship_id`, and backfill `user_friends` (accepted) for existing linked couples. Run BEFORE 051.
51. **051_auto_pair_on_accept.sql** — Trigger on `user_friends` that auto-creates the pair's couple row when a request is accepted; `join_couple_by_code` drops the single-couple gate and records the friendship. Run AFTER 050.
52. **052_resilient_friend_accept.sql** — Fixes "Accept friend request does nothing". 051's trigger used `ON CONFLICT` on the `couples_unique_pair` index, which never built on prod (duplicate self-pair couple rows). Rewrites the trigger to use `IF NOT EXISTS` instead — no unique-index dependency — wrapped in an exception guard so couple-creation can never roll back the accept. Ensures `couples.friendship_id` exists and backfills couple rows for already-accepted friendships. Non-destructive (leaves junk self-pair rows alone); idempotent.
53. **053_auto_populate_display_name.sql** — Every new signup now gets a `profiles.display_name` (trigger `on_auth_user_created` → `handle_new_user`, name from auth metadata else email local part) + re-backfills existing null names. Fixes "Winkidoo user" labels, blank chat sender names, and users being unfindable in search.
54. **054_search_excludes_existing_friends.sql** — `search_users_by_name` RPC now excludes anyone who already has a `user_friends` row with the caller (any direction/status), so you can't re-send a request to an existing/pending friend.
55. **055_friend_notifications.sql** — Trigger `notify_friend_event` on `user_friends` writes an in-app notification on new pending request (→ recipient) and on accept (→ requester). In-app only; push is handled by the edge function + webhook below.
56. **056_chat_member_names_and_approval.sql** — (A) `get_chat_room_members` enriched with `display_name`+`email` so chat shows WhatsApp-style sender names. (B) Adds `character_chat_members.status` ('active'/'pending'); friends added at room creation are active, invite-code joiners (`join_chat_room_by_code`) are pending until a room admin calls `approve_chat_room_member`; pending users can't read/send messages. Plus in-app notifications for join request (→ admin) and approval (→ joiner).
57. **057_collectibles_fk_on_delete.sql** — Fixes "Could not delete" (23503 `judge_collectibles_battle_id_fkey`) when deleting a surprise that earned a collectible. 021 declared `judge_collectibles.battle_id REFERENCES surprises(id)` with no ON DELETE action; recreated as `ON DELETE SET NULL` — the collectible card (a trophy keyed by couple + persona) survives, only its provenance pointer is cleared. Every other FK to `surprises` already cascades.

If you see `relation "public.surprises" does not exist`, run **001** first, then 002, 003, 004, 005, 006, 007, 008.

### Push notifications (Edge Function + webhook)

- Deploy the Edge Function: `supabase functions deploy send_battle_notification`.
- Set secret: `supabase secrets set FIREBASE_SERVICE_ACCOUNT='<full JSON of Firebase service account>'`.
- In Dashboard → Database → Webhooks: (1) Create a webhook on table `public.surprises`, events **INSERT** and **UPDATE**, URL `https://<PROJECT_REF>.supabase.co/functions/v1/send_battle_notification`. (2) Create a second webhook on table `public.judges`, events **INSERT** and **UPDATE**, same URL. Payload for both: include record and old_record.
- **Friend push (added with migration 055):** redeploy `send_battle_notification` (it now has a `user_friends` branch that sends PUSH only — in-app rows come from the 055 trigger). Then create a webhook on table `public.user_friends`, events **INSERT** and **UPDATE**, same URL, include record + old_record. Without this webhook, friend notifications still appear in-app (via the trigger) but won't push while the app is closed.

### RevenueCat webhook (Edge Function)

- Deploy: `supabase functions deploy revenuecat-webhook --use-api`
- Set secret: `supabase secrets set REVENUECAT_WEBHOOK_SECRET='<your_secret>'`
- In RevenueCat dashboard → Integrations → Webhooks:
  - URL: `https://<PROJECT_REF>.supabase.co/functions/v1/revenuecat-webhook`
  - Authorization header: `Bearer <REVENUECAT_WEBHOOK_SECRET>`
- The function updates `couples.wink_plus_until` on purchase/renewal/expiration events.

### delete-account (in-app account deletion — Play Store requirement)

- Deploy: `supabase functions deploy delete-account --use-api`
- No secrets needed beyond the auto-injected `SUPABASE_SERVICE_ROLE_KEY`. No new migration.
- Called from the client (`AccountDeletionService` → Profile → Settings → Delete account) with the user's JWT. Deletes the auth user (cascade clears user-keyed rows) and preserves a partner's shared vault by transferring couple ownership + reassigning the leaving user's surprises/quests first (`quests.creator_id` has no cascade).

### gemini-proxy (server-side Gemini key — keeps the key out of the APK)

- Set the secret: `supabase secrets set GEMINI_API_KEY=<your_key>`
- Deploy: `supabase functions deploy gemini-proxy --use-api`
- Reuses the `check_rate_limit` RPC (migration 042) for a per-user backstop (action `gemini`, 60/min). No new migration.
- The client (`lib/services/gemini_proxy_client.dart`) routes the `google_generative_ai` SDK's traffic here with the user's JWT; the function authenticates the caller, attaches `GEMINI_API_KEY`, and forwards to `generativelanguage.googleapis.com`. The key never ships in the client. Rotate the key any time by updating the secret — no app release needed.
- Also injects `generationConfig.thinkingConfig.thinkingBudget = 0` to disable gemini-2.5-flash "thinking" (which otherwise starves `maxOutputTokens` and broke the judge/chat). See `docs/DATABASE.md` → Edge Functions → gemini-proxy.

### tavily-proxy (server-side Tavily key — keeps it out of the APK)

- Set the secret: `supabase secrets set TAVILY_API_KEY=<your_key>`
- Deploy: `supabase functions deploy tavily-proxy --use-api`
- Reuses `check_rate_limit` (action `tavily`, 20/min). No new migration.
- The client (`lib/services/tavily_search_service.dart`) calls it via `functions.invoke` for custom-judge web search; the function injects `TAVILY_API_KEY` and forwards to `api.tavily.com`. Fails gracefully to AI-only persona generation.

*Doc sync: May 2026 — migrations 001–040 documented. Push (009–010) and Edge Function/webhook steps match docs/FIREBASE_AND_PUSH_SETUP.md. gemini-proxy added 2026-05.*
