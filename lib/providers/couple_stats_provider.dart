import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';

/// Stats computed from resolved surprises for the active couple (read-only, no schema).
class CoupleStats {
  const CoupleStats({
    required this.totalBattles,
    required this.unlockRate,
    required this.toughestJudgePersonaId,
    required this.avgPersuasion,
    required this.creatorDefenseRatio,
    required this.monthlyBattles,
  });

  final int totalBattles;
  final double unlockRate;
  final String toughestJudgePersonaId;
  final double avgPersuasion;
  final double creatorDefenseRatio;
  final Map<String, int> monthlyBattles;
}

/// Last 6 calendar months in order oldest → newest (yyyy-MM).
List<String> _lastSixMonthKeys() {
  final now = DateTime.now();
  final keys = <String>[];
  for (var i = 5; i >= 0; i--) {
    final d = DateTime(now.year, now.month - i, 1);
    keys.add('${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}');
  }
  return keys;
}

final coupleStatsProvider = FutureProvider<CoupleStats>((ref) async {
  final couple = ref.watch(coupleProvider).value;
  final list = ref.watch(surprisesListProvider).value ?? [];
  if (couple == null) {
    final keys = _lastSixMonthKeys();
    return CoupleStats(
      totalBattles: 0,
      unlockRate: 0,
      toughestJudgePersonaId: '',
      avgPersuasion: 0,
      creatorDefenseRatio: 0,
      monthlyBattles: {for (final k in keys) k: 0},
    );
  }

  final resolved =
      list.where((s) => s.battleStatus == 'resolved').toList();
  final totalBattles = resolved.length;

  double unlockRate = 0;
  if (totalBattles > 0) {
    final seekerWins = resolved.where((s) => s.winner == 'seeker').length;
    unlockRate = 100 * seekerWins / totalBattles;
  }

  String toughestJudgePersonaId = '';
  if (totalBattles > 0) {
    final byJudge = <String, List<Surprise>>{};
    for (final s in resolved) {
      byJudge.putIfAbsent(s.judgePersona, () => []).add(s);
    }
    String? lowestPersona;
    double lowestRate = 1.0;
    for (final entry in byJudge.entries) {
      final battles = entry.value;
      final wins = battles.where((s) => s.winner == 'seeker').length;
      final rate = wins / battles.length;
      if (rate < lowestRate) {
        lowestRate = rate;
        lowestPersona = entry.key;
      }
    }
    toughestJudgePersonaId = lowestPersona ?? '';
  }

  double avgPersuasion = 0;
  if (totalBattles > 0) {
    final sum = resolved.fold<int>(0, (s, x) => s + x.seekerScore);
    avgPersuasion = sum / totalBattles;
  }

  double creatorDefenseRatio = 0;
  if (totalBattles > 0) {
    final sum = resolved.fold<int>(0, (s, x) => s + x.creatorDefenseCount);
    creatorDefenseRatio = sum / totalBattles;
  }

  final keys = _lastSixMonthKeys();
  final monthlyBattles = <String, int>{for (final k in keys) k: 0};
  for (final s in resolved) {
    final at = s.resolvedAt;
    if (at != null) {
      final key =
          '${at.year.toString().padLeft(4, '0')}-${at.month.toString().padLeft(2, '0')}';
      if (monthlyBattles.containsKey(key)) {
        monthlyBattles[key] = monthlyBattles[key]! + 1;
      }
    }
  }

  return CoupleStats(
    totalBattles: totalBattles,
    unlockRate: unlockRate,
    toughestJudgePersonaId: toughestJudgePersonaId,
    avgPersuasion: avgPersuasion,
    creatorDefenseRatio: creatorDefenseRatio,
    monthlyBattles: monthlyBattles,
  );
});
