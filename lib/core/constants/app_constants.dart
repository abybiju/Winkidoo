import 'package:flutter/foundation.dart';

/// App-wide constants for Winkidoo.
class AppConstants {
  AppConstants._();

  static const String appName = 'Winkidoo';

  /// OAuth callback URL for mobile (Google/Apple/Facebook). Must be added to Supabase → Auth → URL Configuration → Redirect URLs.
  static const String oAuthRedirectUrl = 'winkidoo://auth/callback';

  /// When true (debug only), treat as Wink+ for testing: all personas + 10 free attempts. Must be false in release.
  static const bool forceWinkPlusForTesting = kDebugMode;

  /// Free tier: 3 judge attempts per day
  static const int freeAttemptsPerDay = 3;

  /// Wink+ tier: more free attempts per day
  static const int winkPlusFreeAttemptsPerDay = 10;

  /// Wink costs
  static const int hintCostWinks = 5;
  static const int instantUnlockCostWinks = 50;

  /// Judge persona IDs (must match DB enum / API)
  static const String personaSassyCupid = 'sassy_cupid';
  static const String personaPoeticRomantic = 'poetic_romantic';
  static const String personaChaosGremlin = 'chaos_gremlin';
  static const String personaTheEx = 'the_ex';
  static const String personaDrLove = 'dr_love';

  static const List<String> freePersonas = [
    personaSassyCupid,
    personaPoeticRomantic,
  ];

  /// Unlock methods
  static const String unlockPersuade = 'persuade';
  static const String unlockCollaborate = 'collaborate';

  /// Difficulty levels (1–5), affect score threshold. Blueprint: Easy 80, Medium 100, Hard 130.
  static const int difficultyMin = 1;
  static const int difficultyMax = 5;

  /// Base resistance scores per blueprint (Easy / Medium / Hard). Level 1–5 maps to these.
  static const int difficultyEasy = 80;
  static const int difficultyMedium = 100;
  static const int difficultyHard = 130;

  /// Resistance points subtracted per seeker message (fatigue decay). Used in effectiveResistance.
  static const int fatigueDecayPerLevel = 2;

  /// Max seeker persuasion score (clamp ceiling). Must be >= max possible effective resistance (~180) so duel is not artificially capped.
  static const int seekerScoreMax = 200;

  /// Auto-delete options (hours). 0 = after viewing only.
  static const List<int> autoDeleteHoursOptions = [0, 24, 48];

  /// Deliberation animation duration (seconds)
  static const int deliberationDurationSeconds = 4;

  /// Live battle: number of rounds (seeker + creator each send this many messages before verdict)
  static const int battleMaxRounds = 3;

  /// Min width (px) for desktop two-panel layout (web). Below = mobile.
  static const double desktopBreakpoint = 700;

  /// Supabase Storage bucket for surprise media (photo, voice, etc.)
  static const String surpriseStorageBucket = 'surprises';

  /// Debounce: don't repeat the same battle system message within this many seconds.
  static const int battleSystemMessageDebounceSeconds = 5;

  /// Minimum effective resistance drop (points) to show "Resistance weakened..." (avoids noise from tiny drops).
  static const int fatigueWeakenedMinDrop = 3;

  // ── Love Quests ──

  /// Min/max steps in a quest chain.
  static const int questMinSteps = 3;
  static const int questMaxSteps = 7;

  /// Quest statuses.
  static const String questStatusActive = 'active';
  static const String questStatusCompleted = 'completed';
  static const String questStatusAbandoned = 'abandoned';

  // ── Daily Streaks ──

  /// Winks cost for a streak freeze (one day).
  static const int streakFreezeCostWinks = 10;

  /// Activity types for daily_activity_log.
  static const String activitySurpriseCreated = 'surprise_created';
  static const String activityMessageSent = 'message_sent';
  static const String activityBattleResolved = 'battle_resolved';
  static const String activityQuestStep = 'quest_step';

  // ── Daily Love Dares ──

  /// Activity type for streak tracking.
  static const String activityDareCompleted = 'dare_completed';

  /// XP awarded when both partners complete a dare.
  static const int xpPerDareCompleted = 15;

  /// Dare categories.
  static const List<String> dareCategories = [
    'romantic',
    'playful',
    'nostalgic',
    'adventurous',
    'chaotic',
  ];

  /// Persona rotation order for daily dares (deterministic: dayOfYear % 5).
  static const List<String> darePersonaRotation = [
    personaSassyCupid,
    personaPoeticRomantic,
    personaChaosGremlin,
    personaTheEx,
    personaDrLove,
  ];

  // ── XP System (Phase 2 prep) ──

  static const int xpPerSurpriseCreated = 10;
  static const int xpPerBattleWon = 25;
  static const int xpPerStreakDay = 5;
  static const int xpPerQuestCompleted = 100;
  static const int xpPerQuestStep = 15;
}
