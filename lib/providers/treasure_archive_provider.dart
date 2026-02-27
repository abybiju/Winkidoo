import 'package:flutter_riverpod/flutter_riverpod.dart';
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
