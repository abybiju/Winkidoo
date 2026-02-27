import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/models/treasure_archive.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

final treasureArchiveListProvider = FutureProvider<List<TreasureArchive>>((ref) async {
  try {
    final client = ref.watch(supabaseClientProvider);
    final couple = ref.watch(coupleProvider).value;
    if (couple == null) return [];

    final data = await client
        .from('treasure_archive')
        .select()
        .eq('couple_id', couple.id)
        .order('archived_at', ascending: false);

    final list = data is List ? data : (data != null ? [data] : <dynamic>[]);
    final results = <TreasureArchive>[];
    for (final r in list) {
      if (r is Map<String, dynamic>) {
        try {
          results.add(TreasureArchive.fromJson(r));
        } catch (_) {}
      }
    }
    return results;
  } catch (_) {
    return [];
  }
});

/// Archive list with corresponding surprise row per item (for seeker_score, resistance_score, difficulty, etc.).
/// Batch-fetches surprises to avoid N+1 requests.
final archiveWithSurprisesProvider =
    FutureProvider<List<({TreasureArchive archive, Surprise? surprise})>>((ref) async {
  final list = await ref.watch(treasureArchiveListProvider.future);
  if (list.isEmpty) return [];
  try {
    final client = ref.watch(supabaseClientProvider);
    final ids = list.map((a) => a.surpriseId).toSet().toList();
    final data = await client.from('surprises').select().inFilter('id', ids);
    final rawList = data is List ? data : (data != null ? [data] : <dynamic>[]);
    final surpriseMap = <String, Surprise>{};
    for (final r in rawList) {
      if (r is Map<String, dynamic>) {
        try {
          final s = Surprise.fromJson(r);
          surpriseMap[s.id] = s;
        } catch (_) {}
      }
    }
    return list
        .map((archive) => (
              archive: archive,
              surprise: surpriseMap[archive.surpriseId],
            ))
        .toList();
  } catch (_) {
    return list.map((archive) => (archive: archive, surprise: null)).toList();
  }
});
