import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

final surprisesListProvider = FutureProvider<List<Surprise>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final couple = await ref.watch(coupleProvider.future);
  if (couple == null) return [];

  final data = await client
      .from('surprises')
      .select()
      .eq('couple_id', couple.id)
      .order('created_at', ascending: false);

  return (data as List)
      .map((r) => Surprise.fromJson(r as Map<String, dynamic>))
      .toList();
});

final surpriseByIdProvider =
    FutureProvider.family<Surprise?, String>((ref, id) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('surprises').select().eq('id', id).maybeSingle();
  if (res == null) return null;
  return Surprise.fromJson(res as Map<String, dynamic>);
});
