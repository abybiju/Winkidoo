import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

/// Daily streak stats backed by the daily_activity_log table.
class StreakStats {
  const StreakStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.activeToday,
    required this.streakTier,
  });

  final int currentStreak;
  final int longestStreak;
  final bool activeToday;

  /// Visual tier for the fire emoji escalation.
  final StreakTier streakTier;
}

/// Fire emoji escalation tiers.
enum StreakTier {
  /// 0 days — no streak
  none,
  /// 1-6 days — single flame
  flame,
  /// 7-29 days — double flame
  doubleFlame,
  /// 30-99 days — blue flame
  blueFlame,
  /// 100+ days — custom animation
  legendary,
}

StreakTier _tierFromDays(int days) {
  if (days <= 0) return StreakTier.none;
  if (days < 7) return StreakTier.flame;
  if (days < 30) return StreakTier.doubleFlame;
  if (days < 100) return StreakTier.blueFlame;
  return StreakTier.legendary;
}

/// Computes current daily streak for the couple.
/// A day counts as active if EITHER partner logged activity.
/// Streak freezes fill in for missing days.
final streakProvider = FutureProvider<StreakStats>((ref) async {
  final couple = ref.watch(coupleProvider).value;
  if (couple == null) {
    return const StreakStats(
      currentStreak: 0,
      longestStreak: 0,
      activeToday: false,
      streakTier: StreakTier.none,
    );
  }

  try {
    final client = ref.watch(supabaseClientProvider);

    // Fetch distinct active dates for the couple (both partners combined)
    final activityData = await client
        .from('daily_activity_log')
        .select('activity_date')
        .eq('couple_id', couple.id)
        .order('activity_date', ascending: false)
        .limit(400); // ~1 year of daily data

    final activeDates = <String>{};
    if (activityData is List) {
      for (final row in activityData) {
        if (row is Map<String, dynamic>) {
          final date = row['activity_date'] as String?;
          if (date != null) activeDates.add(date);
        }
      }
    }

    // Fetch streak freezes for the couple
    final freezeData = await client
        .from('streak_freezes')
        .select('freeze_date')
        .eq('couple_id', couple.id);

    final freezeDates = <String>{};
    if (freezeData is List) {
      for (final row in freezeData) {
        if (row is Map<String, dynamic>) {
          final date = row['freeze_date'] as String?;
          if (date != null) freezeDates.add(date);
        }
      }
    }

    if (activeDates.isEmpty) {
      return const StreakStats(
        currentStreak: 0,
        longestStreak: 0,
        activeToday: false,
        streakTier: StreakTier.none,
      );
    }

    final today = DateTime.now();
    final todayStr = _dateKey(today);
    final activeToday = activeDates.contains(todayStr);

    // Calculate current streak: count consecutive days backwards from today
    int currentStreak = 0;
    var cursor = today;
    while (true) {
      final key = _dateKey(cursor);
      if (activeDates.contains(key) || freezeDates.contains(key)) {
        currentStreak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // Calculate longest streak from all dates
    final allDates = <String>{...activeDates, ...freezeDates};
    final sortedDates = allDates.toList()..sort();
    int longestStreak = 0;
    int run = 1;
    for (var i = 1; i < sortedDates.length; i++) {
      final prev = DateTime.parse(sortedDates[i - 1]);
      final curr = DateTime.parse(sortedDates[i]);
      if (curr.difference(prev).inDays == 1) {
        run++;
      } else {
        if (run > longestStreak) longestStreak = run;
        run = 1;
      }
    }
    if (run > longestStreak) longestStreak = run;
    if (currentStreak > longestStreak) longestStreak = currentStreak;

    return StreakStats(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      activeToday: activeToday,
      streakTier: _tierFromDays(currentStreak),
    );
  } catch (e) {
    debugPrint('streakProvider: $e');
    return const StreakStats(
      currentStreak: 0,
      longestStreak: 0,
      activeToday: false,
      streakTier: StreakTier.none,
    );
  }
});

/// Format date as YYYY-MM-DD for comparison with DB dates.
String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
