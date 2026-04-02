import 'package:flutter/foundation.dart';

/// App-wide constants for Winkidoo.
class AppConstants {
  AppConstants._();

  static const String appName = 'Winkidoo';

  /// OAuth callback URL for mobile (Google/Apple/Facebook). Must be added to Supabase → Auth → URL Configuration → Redirect URLs.
  static const String oAuthRedirectUrl = 'winkidoo://auth/callback';

  /// When true (debug only), treat as Wink+ for testing: all personas + 10 free attempts. Must be false in release.
  static const bool forceWinkPlusForTesting = kDebugMode;

  // ── RevenueCat ──

  /// RevenueCat API key — passed via --dart-define=REVENUECAT_API_KEY=...
  /// Use the Apple API key on iOS/macOS, Google on Android. For simplicity we use one key here;
  /// to split per-platform, add REVENUECAT_GOOGLE_API_KEY and switch in RevenueCatService.
  static const String revenueCatApiKey =
      String.fromEnvironment('REVENUECAT_API_KEY', defaultValue: '');

  /// Entitlement identifier configured in RevenueCat dashboard.
  static const String rcEntitlementWinkPlus = 'wink_plus';

  /// Offering identifier (default offering).
  static const String rcOfferingDefault = 'default';

  /// Product identifiers (must match App Store Connect / Google Play Console).
  static const String rcProductMonthly = 'winkplus_monthly';
  static const String rcProductYearly = 'winkplus_yearly';

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

  // ── Surprise Roulette ──

  /// Weighted segments: Easy 30%, Medium 30%, Hard 25%, Chaos 10%, Golden 5%
  static const Map<String, double> rouletteWeights = {
    'easy': 0.30,
    'medium': 0.30,
    'hard': 0.25,
    'chaos': 0.10,
    'golden': 0.05,
  };

  /// Chaos Mode: random resistance swing per turn
  static const int chaosResistanceSwing = 15;

  /// Chaos Mode: Gemini temperature override
  static const double chaosTemperature = 0.95;

  /// Golden Hour: XP multiplier
  static const int goldenXpMultiplier = 3;

  /// Golden Hour: fatigue decay multiplier
  static const int goldenFatigueMultiplier = 2;

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

  // ── Couple Mini-Games ──

  /// Activity type for streak tracking.
  static const String activityMiniGameCompleted = 'minigame_completed';

  /// XP awarded when both partners complete a mini-game.
  static const int xpPerMiniGameCompleted = 10;

  /// Game type rotation (deterministic: dayOfYear % 4).
  static const List<String> miniGameRotation = [
    'would_you_rather',
    'love_trivia',
    'caption_this',
    'finish_my_sentence',
  ];

  // ── Custom Judge Creator ──

  /// Mood options for custom judges.
  static const List<String> judgeMoods = [
    'funny', 'savage', 'romantic', 'strict', 'chaotic', 'chill',
  ];

  /// Max custom judges a free user can create.
  static const int freeCustomJudgeLimit = 1;

  // ── XP System (Phase 2 prep) ──

  static const int xpPerSurpriseCreated = 10;
  static const int xpPerBattleWon = 25;
  static const int xpPerStreakDay = 5;
  static const int xpPerQuestCompleted = 100;
  static const int xpPerQuestStep = 15;
}
