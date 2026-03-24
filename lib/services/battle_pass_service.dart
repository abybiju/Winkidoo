import 'package:supabase_flutter/supabase_flutter.dart';

class BattlePassTier {
  static String fromPoints(int points) {
    if (points >= 250) return 'gold';
    if (points >= 100) return 'silver';
    return 'bronze';
  }

  static int nextTierPoints(int points) {
    if (points < 100) return 100;
    if (points < 250) return 250;
    return 250;
  }

  static String emoji(String tier) {
    switch (tier) {
      case 'gold': return '🥇';
      case 'silver': return '🥈';
      default: return '🥉';
    }
  }
}

class BattlePassProgress {
  final String seasonName;
  final int points;
  final String tier;
  final DateTime seasonEnd;

  const BattlePassProgress({
    required this.seasonName,
    required this.points,
    required this.tier,
    required this.seasonEnd,
  });
}

class BattlePassService {
  static const int pointsSurpriseCreated = 5;
  static const int pointsBattleWon = 10;
  static const int pointsQuestStep = 5;
  static const int pointsQuestCompleted = 25;

  static Future<BattlePassProgress?> getProgress(
    SupabaseClient client,
    String coupleId,
  ) async {
    try {
      final season = await client
          .from('battle_pass_seasons')
          .select()
          .eq('is_active', true)
          .maybeSingle();
      if (season == null) return null;

      final progress = await client
          .from('battle_pass_progress')
          .select('points, tier')
          .eq('couple_id', coupleId)
          .eq('season_id', season['id'])
          .maybeSingle();

      final points = (progress?['points'] as int?) ?? 0;
      return BattlePassProgress(
        seasonName: season['name'] as String,
        points: points,
        tier: BattlePassTier.fromPoints(points),
        seasonEnd: DateTime.parse(season['end_date'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> awardPoints(
    SupabaseClient client,
    String coupleId,
    int points,
  ) async {
    try {
      final season = await client
          .from('battle_pass_seasons')
          .select('id')
          .eq('is_active', true)
          .maybeSingle();
      if (season == null) return;

      final existing = await client
          .from('battle_pass_progress')
          .select('points')
          .eq('couple_id', coupleId)
          .eq('season_id', season['id'])
          .maybeSingle();

      final current = (existing?['points'] as int?) ?? 0;
      final newPoints = current + points;

      await client.from('battle_pass_progress').upsert({
        'couple_id': coupleId,
        'season_id': season['id'],
        'points': newPoints,
        'tier': BattlePassTier.fromPoints(newPoints),
      });
    } catch (_) {}
  }
}
