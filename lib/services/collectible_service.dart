import 'package:supabase_flutter/supabase_flutter.dart';

class CollectibleService {
  /// Returns rarity string: 'legendary' | 'rare' | 'common'
  static String rarityFor(int seekerScore) {
    if (seekerScore >= 120) return 'legendary';
    if (seekerScore >= 90) return 'rare';
    return 'common';
  }

  /// Awards a collectible card after a battle win. Non-critical.
  static Future<String> awardCard(
    SupabaseClient client, {
    required String coupleId,
    required String judgePersona,
    required String battleId,
    required int seekerScore,
  }) async {
    final rarity = rarityFor(seekerScore);
    try {
      await client.from('judge_collectibles').insert({
        'couple_id': coupleId,
        'judge_persona': judgePersona,
        'rarity': rarity,
        'battle_id': battleId,
        'seeker_score': seekerScore,
      });
    } catch (_) {}
    return rarity;
  }

  /// Fetches all collectibles for a couple.
  static Future<List<Map<String, dynamic>>> getCollectibles(
    SupabaseClient client,
    String coupleId,
  ) async {
    final res = await client
        .from('judge_collectibles')
        .select()
        .eq('couple_id', coupleId)
        .order('earned_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }
}
