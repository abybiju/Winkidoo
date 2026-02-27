# Firebase and push notifications setup (session summary)

Summary of what was done and what remains for Winkidoo push (FCM) and Firebase.

---

## Done (in codebase / by you)

### 1. Edge Function (idempotency and rate-limit note)
- **send_battle_notification**: For UPDATE, only sends when a *relevant* field changed (`battle_status`, `creator_defense_count`, `fatigue_level`, `difficulty_level`, `seeker_score`, `resistance_score`). Early return with `skipped: "no relevant field change"` otherwise. Comment added for future rate limiting (e.g. debounce reinforcement in 10s window).

### 2. Multi-device push tokens
- **Migration 010_user_push_tokens_multi_device.sql**: `user_push_tokens` now has `id` as PK, `push_token` unique (one row per device; one user can have multiple devices).
- **lib/services/push_service.dart**: Upsert uses `onConflict: 'push_token'` so same device updates one row, new devices get new rows.
- Migrations README lists 001–010.

### 3. Firebase project (Firebase Console)
- Firebase project created; Android app added (package `com.winkidoo.winkidoo`), iOS app added, Web app added.
- **android/app/google-services.json** — downloaded and placed (path in `.gitignore`; each dev downloads from Firebase Console).
- **ios/Runner/GoogleService-Info.plist** — downloaded and placed (path in `.gitignore`).
- Web app registered; `firebaseConfig` saved (and added to `web/index.html` in repo).
- Analytics shows 3 apps (Android, iOS, Web); no data yet is expected.
- Deploy to Hosting / custom domain (GoDaddy) left for when you’re ready to go live.

### 4. Android (Gradle / Google services)
- **android/settings.gradle.kts**: `id("com.google.gms.google-services") version "4.4.4" apply false`.
- **android/app/build.gradle.kts**: `id("com.google.gms.google-services")` applied. No manual Firebase BoM/analytics deps (Flutter plugins bring them in).

### 5. iOS (CocoaPods)
- **ios/Podfile**: `platform :ios, '13.0'` uncommented.
- **ios/Flutter/Profile.xcconfig**: Created; includes Pods-Runner profile xcconfig and Generated.xcconfig.
- **Runner.xcodeproj**: Profile build configuration uses `Flutter/Profile.xcconfig`.
- `pod install` runs clean (Firebase SDK 11.15.0 via firebase_core/firebase_messaging).
- No native Swift Firebase init in Xcode (Flutter initializes in Dart in `main.dart`).

### 6. Web (FCM in browser)
- **web/index.html**: Firebase compat scripts (app + messaging) and `firebaseConfig` + `firebase.initializeApp(firebaseConfig)` added so FCM works when running/building for web. Config is client-side only (safe in repo).

### 7. Repo and docs
- **.gitignore**: `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` (per-device; not committed).
- **README.md**: Push notifications step updated — web config in `web/index.html`; Android/iOS configs downloaded from Firebase Console (Winkidoo project) into `android/app/` and `ios/Runner/`; service account key never committed (use Supabase secret).
- **docs/FIREBASE_AND_PUSH_SETUP.md**: This file.

---

## Your side: optional / when ready

1. **If you already committed the JSON/plist**  
   Once, from repo root:  
   `git rm --cached android/app/google-services.json ios/Runner/GoogleService-Info.plist`  
   then commit. Files stay locally; repo no longer tracks them.

2. **Supabase Edge Function and webhook** — **Done.** Function deployed (`supabase functions deploy send_battle_notification`). Secret `FIREBASE_SERVICE_ACCOUNT` set. Database webhook created on `public.surprises`, events INSERT + UPDATE, type Supabase Edge Function → `send_battle_notification`.

3. **Run migration 010** — **Done.** Run in Supabase SQL Editor (multi-device tokens).

4. **Web deploy and domain (later)**  
   When going live: `firebase login`, `firebase init hosting` (public directory `build/web`), `flutter build web`, `firebase deploy`. Add GoDaddy domain in Firebase Hosting → Add custom domain.

---

## Quick reference

| Item | Location / command |
|------|--------------------|
| Firebase Android config | Download from Console → `android/app/google-services.json` (in .gitignore) |
| Firebase iOS config | Download from Console → `ios/Runner/GoogleService-Info.plist` (in .gitignore) |
| Firebase web config | `web/index.html` (Firebase SDK + firebaseConfig) |
| Service account key | Never in repo; `supabase secrets set FIREBASE_SERVICE_ACCOUNT='...'` |
| Deploy function | `supabase functions deploy send_battle_notification` |
| Webhook | Dashboard → Database → Webhooks → `public.surprises`, INSERT+UPDATE, function URL |
| Migrations 001–010 | See supabase/migrations/README.md |

---

---

**Note for future sessions:** This file is the single place that records what was done for Firebase and push. Deploy, secret, webhook, and migration 010 are done. Remaining: optional git rm --cached for JSON/plist if ever committed; Hosting/domain when going live.

*Last updated: February 2026 — Firebase (Android/iOS/Web), Gradle/CocoaPods, web index.html, .gitignore, README; migrations 009–010; Edge Function deployed; FIREBASE_SERVICE_ACCOUNT set; Database webhook on surprises; migration 010 run. Ready for manual testing.*
