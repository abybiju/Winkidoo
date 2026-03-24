import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Logs daily activity for streak tracking.
/// Call after any vault action (surprise created, message sent, battle resolved).
class DailyActivityService {
  DailyActivityService(this._client);

  final SupabaseClient _client;

  /// Log an activity for today. Safe to call multiple times per type per day
  /// (DB has a unique constraint that deduplicates).
  Future<void> logActivity({
    required String coupleId,
    required String activityType,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('daily_activity_log').upsert(
        {
          'user_id': userId,
          'couple_id': coupleId,
          'activity_type': activityType,
          // activity_date defaults to current_date in DB
        },
        onConflict: 'user_id,activity_date,activity_type',
      );
    } catch (e) {
      // Non-critical — don't break the main flow
      debugPrint('DailyActivityService.logActivity: $e');
    }
  }

  /// Purchase a streak freeze for a specific date using Winks.
  /// Returns true if successful.
  Future<bool> purchaseStreakFreeze({
    required String coupleId,
    required DateTime freezeDate,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client.from('streak_freezes').insert({
        'user_id': userId,
        'couple_id': coupleId,
        'freeze_date':
            '${freezeDate.year}-${freezeDate.month.toString().padLeft(2, '0')}-${freezeDate.day.toString().padLeft(2, '0')}',
      });
      return true;
    } catch (e) {
      debugPrint('DailyActivityService.purchaseStreakFreeze: $e');
      return false;
    }
  }
}
