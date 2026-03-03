# Testing Winkidoo from Android Studio

Step-by-step guide to run and validate the app on Android (emulator or device) from Android Studio — UX, UI, and full flow.

---

## 1. One-time Android setup

You may see:

- **"Android sdkmanager not found"** when running `flutter doctor --android-licenses` — you must install the **Android SDK Command-line Tools** first (see below).
- **Android licenses not accepted** — after cmdline-tools are installed, run `flutter doctor --android-licenses` and accept all.

### Step 1: Install Android SDK Command-line Tools (required if sdkmanager not found)

**Using Android Studio (recommended):**

1. Open **Android Studio**.
2. **Settings** (macOS: **Android Studio** → **Preferences**).
3. Go to **Languages & Frameworks** → **Android SDK** (or **Appearance & Behavior** → **System Settings** → **Android SDK**).
4. Open the **SDK Tools** tab.
5. Check **Android SDK Command-line Tools (latest)**.
6. Click **Apply** → **OK** and wait for the install to finish.

**Using terminal (if you don’t use Android Studio):**

1. Download the latest [Command-line tools only](https://developer.android.com/studio#command-line-tools-only) for **Mac** (zip).
2. Run (replace the zip filename with yours):

   ```bash
   mkdir -p ~/Library/Android/sdk/cmdline-tools
   unzip ~/Downloads/commandlinetools-mac-*.zip -d ~/Library/Android/sdk/cmdline-tools
   mv ~/Library/Android/sdk/cmdline-tools/cmdline-tools ~/Library/Android/sdk/cmdline-tools/latest
   ```

3. Ensure `ANDROID_HOME` is set (add to `~/.zshrc` if needed):

   ```bash
   export ANDROID_HOME=$HOME/Library/Android/sdk
   export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
   ```

   Then run `source ~/.zshrc` or open a new terminal.

### Step 2: Accept Android SDK licenses

In a terminal:

```bash
flutter doctor --android-licenses
```

Accept all prompts (`y` + Enter). Then:

```bash
flutter doctor -v
```

You should see the Android toolchain with checkmarks (or only minor warnings).

---

## 2. Open the project in Android Studio

1. **File** → **Open**.
2. Select the **Winkidoo** project folder (the one that contains `pubspec.yaml` and `android/`).
3. Wait for Gradle sync and Flutter/Dart plugins to index.

If Android Studio asks to install Flutter/Dart plugins, do it and restart.

---

## 3. Run configuration (Supabase + Gemini keys)

The app needs environment variables at run time. In Android Studio you pass them as **Additional run arguments**.

1. **Run** → **Edit Configurations…**.
2. Select or create a **Flutter** configuration (e.g. **main.dart** or **winkidoo**).
3. In **Additional run args**, add (replace with your real values):

   ```
   --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co
   --dart-define=SUPABASE_ANON_KEY=your_anon_key_here
   --dart-define=GEMINI_API_KEY=your_gemini_key_here
   ```

   You can use the multi-line field (expand the text box).  
   Get **SUPABASE_URL** and **SUPABASE_ANON_KEY** from Supabase Dashboard → Project Settings → API.  
   Get **GEMINI_API_KEY** from [Google AI Studio](https://aistudio.google.com/apikey).

4. **Apply** → **OK**.

Without these, the app shows a “Missing Supabase configuration” screen; without `GEMINI_API_KEY`, the AI judge will fail when you start a battle.

---

## 4. Device or emulator

### Option A: Android emulator

1. **Tools** → **Device Manager** (or **AVD Manager**).
2. Create a device if needed (e.g. Pixel 6, API 34).
3. Start the emulator (▶️).
4. In the Flutter run configuration, the device dropdown should list the emulator; select it.

### Option B: Physical Android device

1. Enable **Developer options** and **USB debugging** on the device.
2. Connect via USB.
3. Allow USB debugging when prompted on the device.
4. Select the device in the run configuration dropdown.

---

## 5. Run the app

1. Open `lib/main.dart` (or ensure your run configuration points to the right entry).
2. Click **Run** (▶️) or press **Shift+F10** (macOS: **Ctrl+R**).
3. First run may take a few minutes (Gradle + build).

If you see “Missing Supabase configuration”, double-check **Additional run args** and that you applied the configuration.

---

## 6. UX / UI validation checklist

Use this while testing in the app.

### Error and empty states

- [ ] **Vault** — Empty state when there are no surprises (copy and visuals make sense).
- [ ] **Battle / chat** — Error screen if something fails (e.g. network, judge error); message is clear.
- [ ] **Loading** — Skeleton or loading indicators where needed (vault list, battle, judge response).

### Semantics and actions

- [ ] Buttons for main actions have clear labels (e.g. “Sign in”, “Send”, “Create surprise”, “Submit”).
- [ ] Screen reader / TalkBack: critical actions are announced correctly.

### Judge and battle flow

- [ ] Judge tone feels **witty, warm, playful** (and light roasts where intended).
- [ ] Deliberation → reveal flow is clear; confetti on unlock works.
- [ ] Result summary and “Keep in Treasure” / “Delete Forever” behave as expected.

### Theming and layout

- [ ] **Midnight Romance** (dark) theme looks consistent.
- [ ] **Blush & Wink** (if toggled) looks consistent.
- [ ] No obvious layout glitches on the device/emulator you use (e.g. overflow, cut-off text).

### Smoke test (two accounts, full flow)

1. [ ] **Account A**: Sign up / sign in → create couple link → create a **text surprise** (choose judge, difficulty).
2. [ ] **Account B**: Sign up / sign in → join with invite code → see surprise in “Waiting for You”.
3. [ ] **Account B**: Open battle → send submission(s) → judge responds → unlock (or not) → see reveal and confetti if unlocked.
4. [ ] **Account B**: Choose “Keep in Treasure” or “Delete Forever” → vault updates.
5. [ ] **Account A**: See battle result / vault state; open Treasure if applicable.

---

## 7. Quick test without Android (Chrome / macOS)

If you want to validate UI before fixing Android:

- **Chrome:**  
  `flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=GEMINI_API_KEY=...`

- **macOS desktop:**  
  `flutter run -d macos --dart-define=...` (same `--dart-define` args).

Use the same checklist above; layout may differ slightly from Android.

---

## Summary

1. Run `flutter doctor --android-licenses` and fix Android toolchain if needed.
2. Open Winkidoo in Android Studio.
3. **Edit Configurations** → add `--dart-define=SUPABASE_URL=...` (and anon key + Gemini key).
4. Start an emulator or connect a device, then Run.
5. Walk through the UX/UI checklist and the two-account smoke test.

After this, you’re ready to ship MVP1 or move on to Phase 2 (e.g. push, shareable reveal).
