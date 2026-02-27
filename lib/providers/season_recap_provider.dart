import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/models/achievement.dart';
import 'package:winkidoo/models/judge.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

/// Read-only recap for the most recently ended seasonal judge (date window only).
class SeasonRecap {
  const SeasonRecap({
    required this.seasonId,
    required this.seasonTitle,
    required this.seasonStart,
    required this.seasonEnd,
    required this.battlesPlayed,
    required this.winRate,
    required this.avgPersuasion,
    required this.longestStreakDuringSeason,
    required this.achievementsUnlockedDuringSeason,
    this.highlightSurpriseId,
  });

  final String seasonId;
  final String seasonTitle;
  final DateTime seasonStart;
  final DateTime seasonEnd;
  final int battlesPlayed;
  final double winRate;
  final double avgPersuasion;
  final int longestStreakDuringSeason;
  final List<Achievement> achievementsUnlockedDuringSeason;
  final String? highlightSurpriseId;
}

// --- Achievement templates (same ids/titles/descriptions as achievements_provider) ---

List<Achievement> _achievementTemplates() {
  return [
    const Achievement(
      id: 'first_victory',
      title: 'First Victory',
      description: 'Unlock your first surprise by persuading the judge.',
      unlocked: false,
    ),
    const Achievement(
      id: 'battles_5',
      title: '5 Battles Completed',
      description: 'Complete 5 battles.',
      unlocked: false,
    ),
    const Achievement(
      id: 'battles_10',
      title: '10 Battles Completed',
      description: 'Complete 10 battles.',
      unlocked: false,
    ),
    const Achievement(
      id: 'persuasion_100',
      title: '100+ Persuasion',
      description: 'Reach 100 or more persuasion in a single battle.',
      unlocked: false,
    ),
    const Achievement(
      id: 'beat_chaos_gremlin',
      title: 'Beat Chaos Gremlin',
      description: 'Win a battle against the Chaos Gremlin.',
      unlocked: false,
    ),
    const Achievement(
      id: 'creator_defenses_3',
      title: '3+ Creator Defenses',
      description: 'Survive a battle with 3 or more creator defenses in one battle.',
      unlocked: false,
    ),
    const Achievement(
      id: 'active_3_months',
      title: 'Active 3 Months',
      description: 'Have resolved battles in 3 different months.',
      unlocked: false,
    ),
  ];
}

// --- ISO week helpers (duplicated for isolation, used for longest streak in season) ---

int _seasonIsoYear(DateTime date) {
  final weekday = date.weekday;
  final thursday = date.add(Duration(days: 4 - weekday));
  return thursday.year;
}

int _seasonIsoWeek(DateTime date) {
  final weekday = date.weekday;
  final thursday = date.add(Duration(days: 4 - weekday));
  final jan1 = DateTime(thursday.year, 1, 1);
  final days = thursday.difference(jan1).inDays;
  return 1 + (days ~/ 7);
}

String _seasonIsoWeekKey(DateTime date) {
  final y = _seasonIsoYear(date);
  final w = _seasonIsoWeek(date);
  return '$y-${w.toString().padLeft(2, '0')}';
}

(int, int) _seasonParseWeekKey(String key) {
  final parts = key.split('-');
  if (parts.length < 2) return (0, 0);
  final year = int.tryParse(parts[0]) ?? 0;
  final week = int.tryParse(parts[1]) ?? 0;
  return (year, week);
}

bool _seasonIsConsecutiveWeek(int year1, int week1, int year2, int week2) {
  if (year1 == year2) return week2 == week1 + 1;
  if (year2 == year1 + 1) return week1 >= 52 && week2 == 1;
  return false;
}

/// Longest run of consecutive active weeks from [resolved] (each must have resolvedAt).
int _longestStreakInResolved(List<Surprise> resolved) {
  final activeWeekKeys = <String>{};
  for (final s in resolved) {
    final at = s.resolvedAt!;
    activeWeekKeys.add(_seasonIsoWeekKey(at));
  }
  if (activeWeekKeys.isEmpty) return 0;
  final sorted = activeWeekKeys.toList()
    ..sort((a, b) {
      final pa = _seasonParseWeekKey(a);
      final pb = _seasonParseWeekKey(b);
      if (pa.$1 != pb.$1) return pa.$1.compareTo(pb.$1);
      return pa.$2.compareTo(pb.$2);
    });
  int longest = 1;
  int run = 1;
  for (var i = 1; i < sorted.length; i++) {
    final (py, pw) = _seasonParseWeekKey(sorted[i - 1]);
    final (cy, cw) = _seasonParseWeekKey(sorted[i]);
    if (_seasonIsConsecutiveWeek(py, pw, cy, cw)) {
      run++;
    } else {
      if (run > longest) longest = run;
      run = 1;
    }
  }
  if (run > longest) longest = run;
  return longest;
}

/// First unlock date per achievement id (using global resolved sorted by resolvedAt).
Map<String, DateTime?> _firstUnlockDatesByAchievement(List<Surprise> resolved) {
  final sorted = List<Surprise>.from(resolved)
    ..sort((a, b) => (a.resolvedAt!).compareTo(b.resolvedAt!));

  final result = <String, DateTime?>{};

  final firstVictoryList = sorted.where((s) => s.winner == 'seeker').toList();
  result['first_victory'] = firstVictoryList.isEmpty ? null : firstVictoryList.first.resolvedAt;

  result['battles_5'] = sorted.length >= 5 ? sorted[4].resolvedAt : null;
  result['battles_10'] = sorted.length >= 10 ? sorted[9].resolvedAt : null;

  final persuasion100List = sorted.where((s) => s.seekerScore >= 100).toList();
  result['persuasion_100'] = persuasion100List.isEmpty ? null : persuasion100List.first.resolvedAt;

  final beatChaosList = sorted
      .where((s) =>
          s.judgePersona == AppConstants.personaChaosGremlin && s.winner == 'seeker')
      .toList();
  result['beat_chaos_gremlin'] = beatChaosList.isEmpty ? null : beatChaosList.first.resolvedAt;

  final creator3List = sorted.where((s) => s.creatorDefenseCount >= 3).toList();
  result['creator_defenses_3'] = creator3List.isEmpty ? null : creator3List.first.resolvedAt;

  final months = <String>{};
  DateTime? active3Date;
  for (final s in sorted) {
    final at = s.resolvedAt!;
    final key = '${at.year}-${at.month}';
    months.add(key);
    if (months.length >= 3 && active3Date == null) active3Date = at;
  }
  result['active_3_months'] = active3Date;

  return result;
}

/// Pick highlight surprise: max resistance_score; tie-break smallest (resistance - seeker).abs().
String? _pickHighlightSurpriseId(List<Surprise> seasonResolved) {
  final withResistance = seasonResolved.where((s) => s.resistanceScore != null).toList();
  if (withResistance.isEmpty) return null;

  Surprise best = withResistance.first;
  int bestResistance = best.resistanceScore!;
  int bestGap = (bestResistance - best.seekerScore).abs();

  for (final s in withResistance.skip(1)) {
    final r = s.resistanceScore!;
    final gap = (r - s.seekerScore).abs();
    if (r > bestResistance || (r == bestResistance && gap < bestGap)) {
      best = s;
      bestResistance = r;
      bestGap = gap;
    }
  }
  return best.id;
}

final seasonRecapProvider = FutureProvider<SeasonRecap?>((ref) async {
  final couple = ref.watch(coupleProvider).value;
  if (couple == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final now = DateTime.now().toUtc();
  final res = await client
      .from('judges')
      .select()
      .lt('season_end', now.toIso8601String())
      .not('season_start', 'is', null)
      .order('season_end', ascending: false)
      .limit(1);

  final list = res is List ? res : <dynamic>[];
  if (list.isEmpty) return null;
  final e = list.first;
  if (e is! Map<String, dynamic>) return null;
  final judge = Judge.fromJson(e);
  final seasonStart = judge.seasonStart!;
  final seasonEnd = judge.seasonEnd!;

  final surprises = ref.watch(surprisesListProvider).value ?? [];
  final allResolved = surprises
      .where((s) => s.battleStatus == 'resolved' && s.resolvedAt != null)
      .toList();

  final seasonResolved = allResolved.where((s) {
    final at = s.resolvedAt!;
    return !at.isBefore(seasonStart) && !at.isAfter(seasonEnd);
  }).toList();

  final battlesPlayed = seasonResolved.length;
  double winRate = 0;
  double avgPersuasion = 0;
  if (battlesPlayed > 0) {
    final seekerWins = seasonResolved.where((s) => s.winner == 'seeker').length;
    winRate = 100 * seekerWins / battlesPlayed;
    avgPersuasion = seasonResolved.fold<int>(0, (sum, s) => sum + s.seekerScore) / battlesPlayed;
  }

  final longestStreakDuringSeason = _longestStreakInResolved(seasonResolved);

  final firstUnlocks = _firstUnlockDatesByAchievement(allResolved);
  final templates = _achievementTemplates();
  final achievementsUnlockedDuringSeason = <Achievement>[];
  for (final t in templates) {
    final at = firstUnlocks[t.id];
    if (at == null) continue;
    if (!at.isBefore(seasonStart) && !at.isAfter(seasonEnd)) {
      achievementsUnlockedDuringSeason.add(Achievement(
        id: t.id,
        title: t.title,
        description: t.description,
        unlocked: true,
        unlockedAt: at,
      ));
    }
  }

  final highlightSurpriseId = _pickHighlightSurpriseId(seasonResolved);

  return SeasonRecap(
    seasonId: judge.personaId,
    seasonTitle: judge.name,
    seasonStart: seasonStart,
    seasonEnd: seasonEnd,
    battlesPlayed: battlesPlayed,
    winRate: winRate,
    avgPersuasion: avgPersuasion,
    longestStreakDuringSeason: longestStreakDuringSeason,
    achievementsUnlockedDuringSeason: achievementsUnlockedDuringSeason,
    highlightSurpriseId: highlightSurpriseId,
  );
});
