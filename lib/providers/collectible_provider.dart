import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/judge_collectible.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/collectible_service.dart';

final collectiblesProvider = FutureProvider<List<JudgeCollectible>>((ref) async {
  final couple = ref.watch(coupleProvider).value;
  if (couple == null) return [];
  final client = ref.read(supabaseClientProvider);
  final rows = await CollectibleService.getCollectibles(client, couple.id);
  return rows.map(JudgeCollectible.fromJson).toList();
});
