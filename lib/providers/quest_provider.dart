import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/quest.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

/// All quests for the current couple, newest first.
final questsListProvider = FutureProvider<List<Quest>>((ref) async {
  try {
    final client = ref.watch(supabaseClientProvider);
    final couple = ref.watch(coupleProvider).value;
    if (couple == null) return [];

    final data = await client
        .from('quests')
        .select()
        .eq('couple_id', couple.id)
        .order('created_at', ascending: false);

    final list = data is List ? data : <dynamic>[];
    final results = <Quest>[];
    for (final r in list) {
      if (r is Map<String, dynamic>) {
        try {
          results.add(Quest.fromJson(r));
        } catch (_) {}
      }
    }
    return results;
  } catch (e) {
    debugPrint('questsListProvider: $e');
    return [];
  }
});

/// Single quest by ID.
final questByIdProvider =
    FutureProvider.family<Quest?, String>((ref, id) async {
  try {
    final client = ref.watch(supabaseClientProvider);
    final res =
        await client.from('quests').select().eq('id', id).maybeSingle();
    if (res is! Map<String, dynamic>) return null;
    return Quest.fromJson(res);
  } catch (_) {
    return null;
  }
});

/// Surprises belonging to a specific quest, ordered by step.
final questSurprisesProvider =
    FutureProvider.family<List<Surprise>, String>((ref, questId) async {
  try {
    final client = ref.watch(supabaseClientProvider);
    final data = await client
        .from('surprises')
        .select()
        .eq('quest_id', questId)
        .order('quest_step', ascending: true);

    final list = data is List ? data : <dynamic>[];
    final results = <Surprise>[];
    for (final r in list) {
      if (r is Map<String, dynamic>) {
        try {
          results.add(Surprise.fromJson(r));
        } catch (_) {}
      }
    }
    return results;
  } catch (_) {
    return [];
  }
});

/// Active quests only (for home screen display).
final activeQuestsProvider = FutureProvider<List<Quest>>((ref) async {
  final all = await ref.watch(questsListProvider.future);
  return all.where((q) => q.isActive).toList();
});
