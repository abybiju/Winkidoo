import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/judge.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

/// Active judges for selection: permanent (season_start is null) or currently in season.
final activeJudgesProvider = FutureProvider<List<Judge>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client.from('judges').select();
  final list = res is List ? res : <dynamic>[];
  final now = DateTime.now().toUtc();
  final judges = <Judge>[];
  for (final e in list) {
    if (e is! Map<String, dynamic>) continue;
    final judge = Judge.fromJson(e);
    final start = judge.seasonStart;
    final end = judge.seasonEnd;
    final isActive = start == null && end == null ||
        (start != null && end != null && !now.isBefore(start) && !now.isAfter(end));
    if (isActive) judges.add(judge);
  }
  judges.sort((a, b) {
    final at = a.createdAt ?? DateTime(0);
    final bt = b.createdAt ?? DateTime(0);
    return at.compareTo(bt);
  });
  return judges;
});

/// Single judge by persona_id (no season filter). Used for battle/reveal so existing surprises still resolve.
final judgeByPersonaIdProvider =
    FutureProvider.family<Judge?, String>((ref, personaId) async {
  final client = ref.watch(supabaseClientProvider);
  final res = await client
      .from('judges')
      .select()
      .eq('persona_id', personaId)
      .maybeSingle();
  if (res == null || res is! Map<String, dynamic>) return null;
  return Judge.fromJson(res);
});
