# Session Memory (Mar 4, 2026)

This file is a quick restart context for the next working session.

## What was completed
- Home + Vault + Footer + Profile/Winks visual system refresh:
  - Top bar logo now supports textmark-size parity (`matchLogoToWordmark`) and is enabled on Home/Vault.
  - Vault hero/chest overlays are persona + gender aware and use two distinct judge overlays.
  - Vault chest copy fixed to one-line non-overlapping text: "Open your next surprise when it feels right."
  - Bottom nav redesigned with new style system + unique Phosphor icons; center Battle CTA is solid amber (no gradient).
  - Winks and Profile now use the same cinematic background/glow language as Home/Vault.
- Profile avatar system added:
  - Users can upload device image or choose from Wink avatar presets in both profile completion sheet and profile editor.
  - Avatar source priority: uploaded URL > preset asset > fallback initial.
  - New providers: `userAvatarProfileProvider`, `effectiveProfileAvatarProvider`.
  - New service/model: `ProfileAvatarService`, `UserAvatarProfile`, `ProfileAvatarMode`.
- Supabase migration added for avatar persistence and storage policies:
  - New `public.profiles` table + RLS + `updated_at` trigger.
  - Storage bucket/policies for `profile-avatars`.
- Dependency update:
  - Added `phosphor_flutter` for footer icon redesign.

- Refreshed onboarding/get-started hero with new background asset and CTA flow to `/login`.
- Reworked `/login` into premium minimal auth UI with:
  - mode toggle (Sign Up / Log In)
  - Google/Apple/Facebook buttons using asset PNGs
  - show/hide password
  - forgot password affordance for login mode
- Updated Home toward minimal-pro direction while keeping accepted shell/nav:
  - top bar now supports logo + title + bell count + fire streak count
  - orbit strip now contains horizontal avatar rail
  - battle/vault/judge cards updated to glass-dark look
- Added profile-completion gate before create/join flows:
  - collects `name`, `age`, `gender`
  - persists in Supabase auth user metadata
- Added centralized judge image resolver and applied it on major judge surfaces.

## Key implementation files
- `lib/core/widgets/wink_bottom_nav.dart`
- `lib/core/widgets/winkidoo_top_bar.dart`
- `lib/features/vault/vault_list_screen.dart`
- `lib/features/winks/winks_tab_screen.dart`
- `lib/features/profile/profile_screen.dart`
- `lib/core/widgets/profile_completion_sheet.dart`
- `lib/core/constants/avatar_presets.dart`
- `lib/services/profile_avatar_service.dart`
- `lib/providers/user_profile_provider.dart`
- `supabase/migrations/010_profiles_avatar.sql`
- `lib/core/widgets/winkidoo_top_bar.dart`
- `lib/features/home/home_screen.dart`
- `lib/features/home/widgets/*`
- `lib/core/widgets/profile_completion_sheet.dart`
- `lib/providers/user_profile_provider.dart`
- `lib/core/constants/judge_asset_map.dart`
- `lib/features/create/judge_selection_screen.dart`
- `lib/features/battle/pre_battle_tease.dart`
- `lib/features/treasure/treasure_archive_screen.dart`
- `lib/features/treasure/treasure_detail_screen.dart`
- `lib/features/profile/profile_screen.dart`

## Decisions locked
- Top bar actions: Bell + Fire count
- Home style: minimal glass-dark over purple background
- Profile metadata storage: Supabase auth user metadata
- Judge variant rule: opposite gender; `na` => random per session
- Streak badge value: `streakProvider.currentStreak`

## Next iteration suggestions
- Small-screen polish pass for any remaining tight spacing in Home cards
- Replace placeholders with final art for avatars/judges where desired
- Normalize remaining analyzer info-level lints if you want strict-clean CI
