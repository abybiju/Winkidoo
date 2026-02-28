# Winkidoo Design Refinement Plan

Product design lead review — refinement priorities for brand coherence, hierarchy, premium perception, and UX flow. **UI-only** where specified.

---

## ✅ Phase 1 — Design system (DONE)

Tokens and surface/glow system are implemented in `lib/core/theme/app_theme.dart`. Use `AppTheme.primaryPink`, `AppTheme.plum`, `AppTheme.premiumGold`, `AppTheme.bgTop`/`bgBottom`, `AppTheme.surface1`/`surface2`/`surface3`, `AppTheme.pinkGlow`, `AppTheme.goldGlow`. Legacy `primary`/`secondary`/`surface`/`backgroundStart`/`backgroundEnd` map to these.

## ✅ Phase 2 — Auth simplification (DONE)

Emotional welcome: “Winkidoo” + “Unlock the surprise.” (inclusive tagline for couples, friends, family). Two buttons only: Sign In | Create Account → `/login` with `extra: {'mode': 'signIn'|'signUp'}`. Single auth form with mode toggle, plum 30% / primaryPink borders, OAuth (Google, Apple) and back to welcome.

---

## Design system tokens (reference)

| Token | Hex | Use |
|-------|-----|-----|
| **Primary accent (pink)** | `#E85D93` | Primary CTAs, focus states, key actions |
| **Deep plum** | `#6D2E8C` | Borders, secondary accent, glow |
| **Background** | `#0F172A` → `#1B1030` | Gradient (midnight plum) |
| **Surface 1** | Wine ~90% | Default cards |
| **Surface 2** | Wine ~85% | Slightly elevated |
| **Surface 3** | Wine ~80% | Highlight cards (e.g. Judge Spotlight) |
| **Gold (premium)** | `#F5C76B` | Wink+, premium badges, “currency” feel |

**Direction:** Midnight Plum — consistent wine/plum, avoid blue lean on some screens.

---

## 1. Auth flow simplification (high impact)

**Current:** Welcome → Continue → email **or** Welcome → Sign In → email + password. Feels like two separate product moments.

**Target:**

- **Screen 1 — Emotional welcome**  
  - “Winkidoo” + “Unlock the surprise.” (inclusive: couples, friends, family)  
  - Two buttons only: **Sign In** | **Create Account**  
  - No email field on this screen.

- **Screen 2 — Single auth form (reusable)**  
  - Same layout for both modes.  
  - Email + Password + primary CTA.  
  - Toggle link: “No account? **Sign up**” / “Already have an account? **Sign in**” (action word brighter, rest ~60% opacity).  
  - Mode switch changes CTA label and toggle text.

**Sign In/Up form polish:**

- Default input border: plum **30% opacity** (not error-like).  
- Focus: solid pink.  
- Top section: subtle glow behind “Winkidoo” or soft radial gradient pulse so it doesn’t feel flat.

---

## 2. Welcome screen (first impression)

- **Continue = brightest element;** social buttons slightly dimmed (reduce brightness or subtle treatment) so they don’t overpower.  
- **Email field:** default border neutral (plum 30% opacity), not red.  
- **Consider removing Facebook** unless required; reduces clutter and focuses primary CTA.

---

## 3. Home screen hierarchy

- **Depth layers:**  
  - Level 1: Background (deep wine).  
  - Level 2: Default cards (surface 1).  
  - Level 3: Highlight cards (Judge Spotlight — surface 2/3).  
- **Create Surprise:** solid pink primary; **Enter Vault:** outlined, slightly less bright (secondary).  
- **Judge Spotlight:**  
  - Slight glow behind judge icon.  
  - Short tagline, e.g. “Try persuading Sassy Cupid tonight.”  
  - “Explore Judges →” link so it feels alive, not static.

---

## 4. Vault screen

- Top area: add **vault gradient highlight** and/or **“Vault linked”** badge when partner connected.  
- Optionally show **partner name** to humanize.  
- Keep “Hide a surprise” FAB as primary action.

---

## 5. Wink+ screen (monetization psychology)

- **Hero:** Large “Wink+” title + subheading e.g. “Persuade harder. Unlock deeper.” + subtle **gold accent glow**.  
- **Value blocks:** Icon + bold headline + micro description + divider spacing (not plain bullet list).  
- **Pricing block:** e.g. “$4.99/month — Auto-renews. Cancel anytime.” even when active; premium should feel premium.

---

## 6. Profile screen

- **Streak card:** warmer (more orange glow).  
- **Achievements:** slightly elevated (surface/hierarchy).  
- **Wink+ active card:** subtle glow so premium is visible.  
- Subtle divider spacing between major sections.

---

## 7. Post–vault-create flow (UX)

- After creator creates vault: **keep on Vault Sealed** with share options and “Waiting for partner…” state.  
- Only then go to main shell when linked (or when they tap “Enter Vault” if we add it).  
- Increases emotional weight; avoid feeling transactional.

---

## 8. Brand voice

**Target:** Structured Romantic with Playful Undercurrent — not too cute, not too corporate.

---

## Implementation order (suggested)

1. **Design tokens** — Add to `app_theme.dart` (primary pink, surface levels, gold) and use consistently.  
2. **Welcome screen** — Continue prominence, email border 30% plum, optional social dimming/Facebook removal.  
3. **Auth simplification** — Emotional welcome (Sign In / Create Account only) + single reusable auth form with mode toggle and input/focus border fix.  
4. **Home** — Depth layers, Create Surprise vs Enter Vault hierarchy, Judge Spotlight glow + tagline + “Explore Judges →”.  
5. **Wink+** — Hero, value blocks, pricing block, gold accent.  
6. **Profile** — Streak warmth, Achievements elevation, Wink+ glow, dividers.  
7. **Vault** — Top gradient/badge, optional partner name.  
8. **Post-create flow** — Confirm Vault Sealed is the only post-create destination until linked (already in router); add “Waiting for partner…” and share emphasis if not already clear.

---

*Document created from product design lead review. No secrets; UI/UX only.*
