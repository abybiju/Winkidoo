# OAuth and store setup (no secrets)

Step-by-step for Google, Apple, and Facebook (Meta) sign-in and app store readiness. **Do not put API keys, client secrets, or tokens in this file or in the repo.**

---

## 1. Supabase Auth providers

- In **Supabase Dashboard → Authentication → Providers**, enable **Google**, **Apple**, and **Facebook** as needed.
- Under **URL Configuration**, set **Site URL** (e.g. your production origin or `https://winkidoo.com`).
- Add **Redirect URLs**: your site URL **and** the mobile OAuth callback **`winkidoo://auth/callback`** (required for Google/Apple/Facebook sign-in on device). Without this, the browser will redirect to localhost or Site URL and “This site can’t be reached” on the phone.

---

## 2. Google OAuth (Android)

1. **Google Cloud Console** → APIs & Services → Credentials → Create **OAuth 2.0 Client ID**.
2. Application type: **Android**.
3. **Package name:** from `android/app/build.gradle.kts` (e.g. `com.winkidoo.winkidoo`).
4. **SHA-1 certificate fingerprint:**
   - If you don’t have Java in PATH, use Android Studio’s JBR, e.g.  
     `export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"`
   - From project root: `cd android && ./gradlew signingReport`
   - In the report, find **Variant: debug** (or release) → **SHA1:** and copy the value (e.g. `03:A7:9C:...`).
5. Paste SHA-1 into the Google Cloud OAuth client and create. Copy the **Client ID** (ends in `.apps.googleusercontent.com`).
6. In **Supabase → Auth → Providers → Google**, paste the **Client ID**. For **Client Secret**, use the value from Google Cloud (Web application type client or the secret from the same project). Store the secret only in Supabase or env; never commit it.

---

## 3. Apple Sign in

- Requires **Apple Developer Program** (paid).
- In **Apple Developer → Certificates, Identifiers & Profiles**:
  - Create an **App ID** with Sign in with Apple capability.
  - Create a **Services ID** for “Sign in with Apple” and set the redirect URL (Supabase gives you the exact URL).
  - Create a **Key** for Sign in with Apple and download the `.p8`; note Key ID and Team ID.
- In **Supabase → Auth → Providers → Apple**, enter **Services ID**, **Secret Key** (generated from the .p8), **Key ID**, **Team ID**, **Bundle ID**. Never commit the .p8 or secret.
- You can ship **Android-first** and add Apple later if you don’t have a developer account yet.

---

## 4. Facebook (Meta) Login

1. **Meta for Developers** → Create app (e.g. Consumer or Business) → add product **Facebook Login**.
2. **App settings → Basic:**
   - **App icon:** 1024×1024 (e.g. from repo `assets/images/app_icon_1024.png`).
   - **Privacy policy URL:** e.g. `https://winkidoo.com/privacy-policy.html` (see **docs/META_APP_URLS.md**).
   - **User data deletion:** “Data deletion instructions URL” → e.g. `https://winkidoo.com/data-deletion.html`.
   - **Category:** e.g. **Social networks & dating**.
   - **Contact email:** your support email (do not commit in public).
3. **Facebook Login → Settings:** add **Valid OAuth Redirect URIs** from Supabase (Auth → Providers → Facebook shows the redirect URL).
4. **Android:** Add platform Android; **Package name** and **Key hashes** (same SHA-1 as for Google). **Google Play Package Name** optional until you publish.
5. In **Supabase → Auth → Providers → Facebook**, enter **App ID** and **App Secret** from Meta. Never commit App Secret.
6. In the app, use **App ID** and **Client Token** (from Meta Basic settings) only where needed for SDK init; prefer env or build config, not hardcoded in repo.

---

## 5. Deep links (mobile OAuth return)

- **Android:** In `AndroidManifest.xml`, add an intent filter for your scheme (e.g. `winkidoo://`). Supabase Auth docs list the exact path (e.g. `winkidoo://auth/callback`).
- **iOS:** In Xcode, add **URL Types** with your scheme (e.g. `winkidoo`).
- Add the full callback URL (e.g. `winkidoo://auth/callback`) to **Supabase → Auth → URL Configuration → Redirect URLs** and to the provider (Google/Apple/Facebook) where redirect URIs are configured.

---

## 6. App store readiness (checklist)

- **App icon** 1024×1024 (used for Meta, Apple, Google Play).
- **Privacy policy URL** (public; e.g. winkidoo.com or GitHub Pages).
- **User data deletion** URL or instructions (Meta and some stores require this).
- **Category** (e.g. Social networks & dating, Lifestyle).
- **Contact email** for support (not committed in repo).

Apple App Store and Google Play require developer accounts (Apple is paid). You can complete Meta and Google OAuth for Android first, then add Apple and store submissions when ready.

---

*Last updated: February 2026. No secrets or keys are stored in this file.*
