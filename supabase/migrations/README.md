# Winkidoo Supabase migrations

Run these in order in the Supabase SQL Editor (Dashboard → SQL Editor → New query):

1. **001_initial_schema.sql** — `couples`, `surprises`, `attempts`, `winks_balance`, `transactions`, RLS, triggers
2. **002_battle_messages.sql** — `battle_messages` for live judge chat
3. **003_wink_plus.sql** — `wink_plus_until` on `couples`
4. **004_surprise_type_photo.sql** — `surprise_type`, `content_storage_path` on `surprises`
5. **005_blueprint_v1_schema.sql** — `battle_status`, `archived_flag`, battle state columns on `surprises`; `treasure_archive`; `judges`

If you see `relation "public.surprises" does not exist`, run **001** first, then 002, 003, 004, 005.
