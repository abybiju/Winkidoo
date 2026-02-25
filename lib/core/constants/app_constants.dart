/// App-wide constants for Winkidoo.
class AppConstants {
  AppConstants._();

  static const String appName = 'Winkidoo';

  /// Free tier: 3 judge attempts per day
  static const int freeAttemptsPerDay = 3;

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

  /// Difficulty levels (1–5), affect score threshold
  static const int difficultyMin = 1;
  static const int difficultyMax = 5;

  /// Auto-delete options (hours). 0 = after viewing only.
  static const List<int> autoDeleteHoursOptions = [0, 24, 48];

  /// Deliberation animation duration (seconds)
  static const int deliberationDurationSeconds = 4;

  /// Live battle: number of rounds (seeker + creator each send this many messages before verdict)
  static const int battleMaxRounds = 3;
}
