# Winkidoo Product Blueprint v1 (source of truth)

This document references the official **Winkidoo Product Blueprint v1**. The codebase and UX are aligned to this blueprint.

## Core identity

- **1v1 couples/friends app**: one shared vault per couple; both can create surprises.
- **Unlock mechanic**: seeker persuades an AI Judge; creator chooses the judge at creation time and may optionally defend.
- **Vibe**: Emotional, competitive, character-driven, AI-powered, playful-chaotic with bold undertones.

## Relationship and vault

- Effectively one active partner; one shared vault per couple.
- Vault sections: **Waiting for You** (partner’s surprises) and **Your Surprises** (yours).
- Each surprise has creator, content (text/photo/voice), judge persona, auto-delete, battle state, and archived flag.

## Battle system (Blueprint)

- **One battle per surprise**; no rematch.
- **Dynamic Resistance Score (DRS)** = Base + Chaos + Creator reinforcement − Fatigue decay.
- **Base difficulty**: Easy 80, Medium 100, Hard 130 (mapped from difficulty level).
- **Creator reinforcement**: defense messages add resistance with diminishing returns.
- **Fatigue decay**: resistance weakens over seeker attempts (and optionally after 24h inactivity).
- **Emotional states** (no visible numeric score): Cold → Curious → Intrigued → Cracking → Unlock.

## Post-battle and archive

- After battle: **Result Summary** (judge, attempts, interventions, winner, quote) then **Keep in Treasure** or **Delete Forever**.
- **Treasure Archive**: metadata for kept battles; Wink+ can reopen revealed content.

## Winks and Wink+

- **Winks**: hint, instant unlock; seeker persuasion boost / reduce resistance; creator shield / block fatigue.
- **Wink+**: unlimited attempts, all judges, seasonal access, reopen archived content, exclusive skins.

## Ethical design

- No forced waiting, no hostage mechanics, no permanent lock (fatigue + time decay), no pay-to-win.
- Clear delete confirmation and transparent agency.

## Data (high level)

- Core: users, couples, surprises (with battle_status, archived_flag, battle state columns), battle_messages, treasure_archive, judges, winks_balance, transactions, subscriptions (Wink+).

See the full Blueprint v1 document for detailed formulas, UI layout (judge avatar, tug-of-war meter, result summary), and seasonal judges.
