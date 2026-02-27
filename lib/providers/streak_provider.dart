import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';

/// Weekly activity streak stats (read-only, no schema).
/// Week = ISO week; at least one resolved battle in a week counts as active.
class StreakStats {
  const StreakStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.activeThisWeek,
  });

  final int currentStreak;
  final int longestStreak;
  final bool activeThisWeek;
}

/// Returns ISO week year for [date] (year of the week's Thursday).
int _isoYear(DateTime date) {
  final weekday = date.weekday;
  final thursday = date.add(Duration(days: 4 - weekday));
  return thursday.year;
}

/// Returns ISO week number (1–53) for [date].
int _isoWeek(DateTime date) {
  final weekday = date.weekday;
  final thursday = date.add(Duration(days: 4 - weekday));
  final jan1 = DateTime(thursday.year, 1, 1);
  final days = thursday.difference(jan1).inDays;
  return 1 + (days ~/ 7);
}

/// ISO week key for grouping/sorting: "yyyy-Www" (e.g. "2026-W09").
String _isoWeekKey(DateTime date) {
  final y = _isoYear(date);
  final w = _isoWeek(date);
  return '$y-${w.toString().padLeft(2, '0')}';
}

/// Parses "yyyy-Www" to (year, week) for ordering.
(int, int) _parseWeekKey(String key) {
  final parts = key.split('-');
  if (parts.length < 2) return (0, 0);
  final year = int.tryParse(parts[0]) ?? 0;
  final week = int.tryParse(parts[1]) ?? 0;
  return (year, week);
}

/// True iff (year1, week1) is immediately before (year2, week2).
bool _isConsecutiveWeek(int year1, int week1, int year2, int week2) {
  if (year1 == year2) return week2 == week1 + 1;
  if (year2 == year1 + 1) return week1 >= 52 && week2 == 1;
  return false;
}

final streakProvider = FutureProvider<StreakStats>((ref) async {
  final couple = ref.watch(coupleProvider).value;
  final list = ref.watch(surprisesListProvider).value ?? [];

  if (couple == null) {
    return const StreakStats(
      currentStreak: 0,
      longestStreak: 0,
      activeThisWeek: false,
    );
  }

  final resolved = list
      .where((s) => s.battleStatus == 'resolved' && s.resolvedAt != null)
      .toList();

  final activeWeekKeys = <String>{};
  for (final s in resolved) {
    final at = s.resolvedAt!;
    activeWeekKeys.add(_isoWeekKey(at));
  }

  if (activeWeekKeys.isEmpty) {
    return const StreakStats(
      currentStreak: 0,
      longestStreak: 0,
      activeThisWeek: false,
    );
  }

  final sortedWeeks = activeWeekKeys.toList()..sort((a, b) {
        final pa = _parseWeekKey(a);
        final pb = _parseWeekKey(b);
        if (pa.$1 != pb.$1) return pa.$1.compareTo(pb.$1);
        return pa.$2.compareTo(pb.$2);
      });

  final now = DateTime.now();
  final thisWeekKey = _isoWeekKey(now);
  final activeThisWeek = activeWeekKeys.contains(thisWeekKey);

  int currentStreak = 0;
  DateTime cursor = now;
  while (activeWeekKeys.contains(_isoWeekKey(cursor))) {
    currentStreak++;
    cursor = cursor.subtract(const Duration(days: 7));
  }

  int longestStreak = 1;
  int run = 1;
  for (var i = 1; i < sortedWeeks.length; i++) {
    final (py, pw) = _parseWeekKey(sortedWeeks[i - 1]);
    final (cy, cw) = _parseWeekKey(sortedWeeks[i]);
    if (_isConsecutiveWeek(py, pw, cy, cw)) {
      run++;
    } else {
      if (run > longestStreak) longestStreak = run;
      run = 1;
    }
  }
  if (run > longestStreak) longestStreak = run;

  return StreakStats(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    activeThisWeek: activeThisWeek,
  );
});
