import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralizes battle resolution so push notifications, background processing,
/// and realtime triggers can resolve battles from a single place.
class BattleService {
  BattleService(this._client);

  final SupabaseClient _client;

  /// Marks the surprise battle as resolved with seeker as winner.
  /// Optionally includes final battle state (scores) in the same write.
  Future<void> resolveAsSeekerWin(
    String surpriseId, {
    String? lastActivityAt,
    int? seekerScore,
    int? resistanceScore,
    int? fatigueLevel,
  }) async {
    final now = lastActivityAt ??
        DateTime.now().toUtc().toIso8601String();
    final update = <String, dynamic>{
      'is_unlocked': true,
      'unlocked_at': now,
      'battle_status': 'resolved',
      'resolved_at': now,
      'winner': 'seeker',
    };
    if (seekerScore != null) update['seeker_score'] = seekerScore;
    if (resistanceScore != null) update['resistance_score'] = resistanceScore;
    if (fatigueLevel != null) update['fatigue_level'] = fatigueLevel;
    if (lastActivityAt != null) update['last_activity_at'] = lastActivityAt;

    await _client.from('surprises').update(update).eq('id', surpriseId);
  }
}
