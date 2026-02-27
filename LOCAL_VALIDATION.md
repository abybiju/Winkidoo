# Local validation checklist (run when you sit to work)

Use this **before or during** your next dev session to confirm Part 2 polish and prepare for Part 1 smoke-test.

*Last doc update: February 2026 — error screens, semantics, SkeletonMessageRow, judge tone, push setup (see docs/FIREBASE_AND_PUSH_SETUP.md).*

---

## 1. Error paths

- **Vault load failure:** Simulate (e.g. temporarily break Supabase query in `surprisesListProvider`) → expect **ErrorScreen** with “Could not load surprises. Try again?” and **Retry** button.
- **Battle messages fail:** Force battle messages load to fail → expect **ErrorScreen** in chat area with **Try again** and **Go back**; **Go back** pops to vault.
- **Non-existent surprise:** Open battle for invalid ID → full-screen **ErrorScreen** with retry/back.

---

## 2. Semantics (accessibility)

Turn on **TalkBack** (Android) or **VoiceOver** (iOS/macOS). Navigate and confirm:

- **Submission screen** → “Send submission to judge, button”.
- **Battle chat** send button → “Send message to judge, button”.
- **Create surprise** type selector → grouped label including selected type (Text / Photo / Voice).
- **Create surprise** submit → “Create surprise, button”.

Optional: Chrome + screen reader extension (e.g. ChromeVox) on web.

---

## 3. Loading skeletons

- **Battle chat:** Open battle with slow network (DevTools throttling) → alternating **SkeletonMessageRow** placeholders (left/right), no spinner.
- **Surprise loading:** When surprise is loading, full-screen shows gradient + 3 skeleton rows (no spinner).
- Vault list loading already uses 4× **SkeletonCard** (no change needed).

---

## 4. Judge tone spot-check

- Run a few battles with different personas.
- Commentary should feel **witty, warm, a little romantic**; roasts **playful, not mean**.

---

## 5. After validation: Part 1 manual smoke-test

When the above looks good:

1. **Two accounts:** A creates couple link → B joins with code.
2. **Vault + create:** A creates text, photo, voice surprise → B sees in “Waiting for you” (realtime).
3. **Battle:** Classic submission + live chat; test Winks (free attempts, hint 5, unlock 50).
4. **Reveal:** Win (confetti + content) and lose (hint/unlock options); haptics on device.
5. **Platform:** Web (responsive, file picker), Android (permissions, vibration), iOS (mic/camera, dark mode).

Roughly **30–60 min**. Then you can call MVP1 done and move to Phase 2 (e.g. push notifications or shareable reveal cards).

---

## Quick run commands

```bash
flutter pub get
flutter run -d chrome   # or -d macos, -d android, etc.
```

For throttling: Chrome DevTools → Network → throttling (e.g. Slow 3G) while opening battle chat.
