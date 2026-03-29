import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Per-couple daily rate limits to control API costs.
class RateLimitService {
  /// Max custom judges a couple can create per day.
  static const int maxCustomJudgesPerDay = 3;

  /// Checks if the couple can create another custom judge today.
  /// Returns (canCreate, remaining).
  /// In debug mode, limit is bypassed for testing.
  static Future<(bool, int)> canCreateCustomJudge(
    SupabaseClient client,
    String coupleId,
  ) async {
    // No limit in debug mode for testing
    if (kDebugMode) return (true, 999);

    try {
      final today = _todayString();
      final rows = await client
          .from('custom_judges')
          .select('id')
          .eq('couple_id', coupleId)
          .gte('created_at', '${today}T00:00:00')
          .lt('created_at', '${_tomorrowString()}T00:00:00');

      final count = (rows as List).length;
      final remaining = (maxCustomJudgesPerDay - count).clamp(0, maxCustomJudgesPerDay);
      return (count < maxCustomJudgesPerDay, remaining);
    } catch (e) {
      debugPrint('RateLimitService.canCreateCustomJudge: $e');
      return (true, maxCustomJudgesPerDay);
    }
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _tomorrowString() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
  }
}
