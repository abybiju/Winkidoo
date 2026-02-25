import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

/// Set when realtime detects a new surprise created by the partner; vault listens and shows snackbar.
final partnerAddedSurpriseAtProvider = StateProvider<DateTime?>((ref) => null);

final surprisesListProvider = FutureProvider<List<Surprise>>((ref) async {
  try {
    final client = ref.watch(supabaseClientProvider);
    final couple = ref.watch(coupleProvider).value;
    if (couple == null) return [];

    final data = await client
        .from('surprises')
        .select()
        .eq('couple_id', couple.id)
        .order('created_at', ascending: false);

    final list = data is List ? data : (data != null ? [data] : <dynamic>[]);
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

final surpriseByIdProvider =
    FutureProvider.family<Surprise?, String>((ref, id) async {
  try {
    final client = ref.watch(supabaseClientProvider);
    final res = await client.from('surprises').select().eq('id', id).maybeSingle();
    if (res is! Map<String, dynamic>) return null;
    return Surprise.fromJson(res);
  } catch (_) {
    return null;
  }
});
