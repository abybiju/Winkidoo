# Winkidoo – Decision Log

Key architectural and product decisions. Keep updated so we don’t repeat mistakes or lose context.

---

## 2026-02-23

- **Evolved concept:** Winkidoo is a "Digital Surprise Vault" for couples, not only hidden text. Unlock can be any digital surprise (text MVP1; later photo, voice, etc.). AI judge is a character with multiple personas.
- **MVP1 scope:** Text-only surprises. Both unlock methods: Persuade (one convinces judge) and Collaborate (both submit). All 5 judge personas in MVP1. Dynamic win threshold = persona base + difficulty × 5. Google Gemini Flash for judge. Full Winks economy from day one. Dark mysterious aesthetic. Privacy: client-side encryption + auto-delete. Accessibility: semantics and system text scaling.
- **Stack:** Flutter 3.22+, Supabase (Auth, Realtime, Postgres), Riverpod 2.x (no code gen for now), Gemini Flash, encrypt package for AES.
- **Models:** Plain Dart classes with fromJson/toJson (no Freezed code gen in repo) for Surprise, Attempt, Couple, JudgeResponse, WinksBalance.
- **Encryption:** Key derived from couple_id so both partners can decrypt. Server only stores ciphertext. True E2E with shared secret can be added later.
- **Winks:** New users get 10 Winks (row created on first balance read). Free tier: 3 attempts/day. Extra attempt costs 1 Wink. Hint 5 Winks, instant unlock 50 Winks (UI later).
- **Realtime:** Supabase Realtime channel on `surprises` filtered by `couple_id`; on event we invalidate surprisesListProvider so vault list refreshes.
- **Schema:** `couples`, `surprises`, `attempts`, `winks_balance`, `transactions`. RLS so users only see their couple’s data and own winks/transactions.
- **Supabase config at runtime:** Never initialize Supabase with empty URL/key. In `main.dart`, check `String.fromEnvironment('SUPABASE_URL'/'SUPABASE_ANON_KEY')` and if empty show `ConfigErrorApp`; otherwise initialize. Local dev may use default values in code; production should use `--dart-define` and not commit keys.
- **Couple provider robustness:** Supabase can return `[]` or non-Map for “no couple” / single-row queries. In `couple_provider.dart` only parse when result `is Map<String, dynamic>`; wrap in try/catch and return `null` on error so UI shows link screen, not “Something went wrong”.
- **Join-by-code robustness:** Join flow uses `.maybeSingle()`; response may be List or other type on some platforms. In `couple_link_screen.dart` treat result as valid only when `raw is Map<String, dynamic>`, then use `res['id']` for the update.
- **Testing couple link:** Use two different Supabase accounts (two emails) to test create vs join; same account on two devices will consume the code (user_b_id set to same user) and show “already used” on retry.
