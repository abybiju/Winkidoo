import 'dart:math' as math;

import 'package:winkidoo/core/constants/app_constants.dart';

/// Shared battle math: resistance (base + creator reinforcement) and fatigue.
/// Used when persisting resistance_score and fatigue_level on surprises.
class BattleMath {
  BattleMath._();

  /// Base resistance from difficulty level (1–5). Blueprint: Easy 80, Medium 100, Hard 130.
  static int baseResistance(int difficultyLevel) {
    const levelToBase = {
      1: AppConstants.difficultyEasy,
      2: 90,
      3: AppConstants.difficultyMedium,
      4: 115,
      5: AppConstants.difficultyHard,
    };
    return levelToBase[difficultyLevel.clamp(1, 5)] ?? AppConstants.difficultyMedium;
  }

  /// Creator reinforcement: diminishing per defense (first +10, then ~20% less each time).
  /// Total = 10 * (1 + 0.8 + 0.8^2 + ... ) for count defenses = 50 * (1 - 0.8^count).
  static int creatorReinforcement(int creatorDefenseCount) {
    if (creatorDefenseCount <= 0) return 0;
    final sum = 50.0 * (1.0 - math.pow(0.8, creatorDefenseCount));
    return sum.round();
  }

  /// Full resistance_score = base + creator reinforcement (no fatigue decay). Prefer [effectiveResistance] for persistence.
  static int resistanceScore({
    required int difficultyLevel,
    required int creatorDefenseCount,
  }) {
    return baseResistance(difficultyLevel) + creatorReinforcement(creatorDefenseCount);
  }

  /// Effective resistance = base + reinforcement - fatigueDecay. More seeker attempts lower the bar. Floored at 0.
  ///
  /// Fatigue: V1 uses [fatigueLevel] = seeker message count only (each seeker message increases fatigue equally).
  /// Future options (creator defense increasing fatigue, long pauses reducing it, Winks modifying it) would require a different formula.
  static int effectiveResistance({
    required int difficultyLevel,
    required int creatorDefenseCount,
    required int fatigueLevel,
    String? rouletteResult,
  }) {
    final fatigueMultiplier =
        rouletteResult == 'golden' ? AppConstants.goldenFatigueMultiplier : 1;
    final raw = baseResistance(difficultyLevel) +
        creatorReinforcement(creatorDefenseCount) -
        (fatigueLevel * AppConstants.fatigueDecayPerLevel * fatigueMultiplier);
    return raw < 0 ? 0 : raw;
  }

  /// Maps a roulette result to a difficulty level for base resistance.
  static int difficultyForRoulette(String rouletteResult) {
    switch (rouletteResult) {
      case 'easy':
      case 'golden':
        return 1; // Easy (80)
      case 'medium':
        return 3; // Medium (100)
      case 'hard':
      case 'chaos':
        return 5; // Hard (130)
      default:
        return 3;
    }
  }
}
