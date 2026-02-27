import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/models/achievement.dart';
import 'package:winkidoo/providers/couple_stats_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';

/// All achievement definitions (id, title, description). Unlocked computed in provider.
List<Achievement> _allAchievementTemplates() {
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

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final stats = await ref.watch(coupleStatsProvider.future);
  final list = ref.watch(surprisesListProvider).value ?? [];
  final resolved = list.where((s) => s.battleStatus == 'resolved').toList();

  final templates = _allAchievementTemplates();
  final result = <Achievement>[];

  final hasFirstVictory = resolved.any((s) => s.winner == 'seeker');
  final battles5 = stats.totalBattles >= 5;
  final battles10 = stats.totalBattles >= 10;
  final persuasion100 = resolved.any((s) => s.seekerScore >= 100);
  final beatChaosGremlin = resolved.any((s) =>
      s.judgePersona == AppConstants.personaChaosGremlin && s.winner == 'seeker');
  final creatorDefenses3 = resolved.any((s) => s.creatorDefenseCount >= 3);
  final months = resolved
      .where((s) => s.resolvedAt != null)
      .map((s) => '${s.resolvedAt!.year}-${s.resolvedAt!.month}')
      .toSet();
  final active3Months = months.length >= 3;

  final checks = {
    'first_victory': hasFirstVictory,
    'battles_5': battles5,
    'battles_10': battles10,
    'persuasion_100': persuasion100,
    'beat_chaos_gremlin': beatChaosGremlin,
    'creator_defenses_3': creatorDefenses3,
    'active_3_months': active3Months,
  };

  for (final t in templates) {
    result.add(Achievement(
      id: t.id,
      title: t.title,
      description: t.description,
      unlocked: checks[t.id] ?? false,
      unlockedAt: (checks[t.id] ?? false) ? null : null,
    ));
  }

  return result;
});
