import 'package:winkidoo/models/surprise.dart';

/// App-level view model for battle state. Surprise remains the DB source of truth.
/// Explicit state: active, resolved, archived (do not infer from winner == null).
class Battle {
  const Battle({
    required this.surpriseId,
    required this.seekerScore,
    this.resistanceScore,
    required this.fatigueLevel,
    this.lastActivityAt,
    this.winner,
    required this.creatorDefenseCount,
    required this.isActive,
    this.resolvedAt,
    this.isArchived = false,
    this.surprise,
  });

  final String surpriseId;
  final int seekerScore;
  final int? resistanceScore;
  final int fatigueLevel;
  final DateTime? lastActivityAt;
  final String? winner;
  final int creatorDefenseCount;
  /// True while battle is in progress; false when resolved (or archived).
  final bool isActive;
  /// When the battle was resolved (null while active).
  final DateTime? resolvedAt;
  /// True when kept in Treasure (archived).
  final bool isArchived;
  final Surprise? surprise;

  /// Build Battle from existing Surprise battle fields.
  static Battle fromSurprise(Surprise s) {
    return Battle(
      surpriseId: s.id,
      seekerScore: s.seekerScore,
      resistanceScore: s.resistanceScore,
      fatigueLevel: s.fatigueLevel,
      lastActivityAt: s.lastActivityAt,
      winner: s.winner,
      creatorDefenseCount: s.creatorDefenseCount,
      isActive: s.battleStatus != 'resolved',
      resolvedAt: s.resolvedAt,
      isArchived: s.archivedFlag,
      surprise: s,
    );
  }

  bool get isResolved => !isActive;
}
