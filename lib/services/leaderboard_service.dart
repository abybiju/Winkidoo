import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/models/leaderboard_entry.dart';

class LeaderboardService {
  static Future<List<LeaderboardEntry>> getLeaderboard(
    SupabaseClient client, {
    int limit = 50,
  }) async {
    final res = await client
        .from('couple_xp')
        .select('couple_id, total_xp, current_level')
        .order('total_xp', ascending: false)
        .limit(limit);

    final rows = List<Map<String, dynamic>>.from(res as List);
    return rows.asMap().entries.map((e) {
      final row = e.value;
      return LeaderboardEntry(
        coupleId: row['couple_id'] as String,
        totalXp: row['total_xp'] as int,
        currentLevel: row['current_level'] as int,
        rank: e.key + 1,
      );
    }).toList();
  }
}
