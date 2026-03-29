import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/custom_judge.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/custom_judge_service.dart';

/// The couple's own custom judges.
final myCustomJudgesProvider = FutureProvider<List<CustomJudge>>((ref) async {
  final couple = ref.watch(coupleProvider).value;
  if (couple == null) return [];
  final client = ref.read(supabaseClientProvider);
  return CustomJudgeService.getMyJudges(client, couple.id);
});

/// Judges the couple has adopted from the marketplace.
final adoptedJudgesProvider = FutureProvider<List<CustomJudge>>((ref) async {
  final couple = ref.watch(coupleProvider).value;
  if (couple == null) return [];
  final client = ref.read(supabaseClientProvider);
  return CustomJudgeService.getAdoptedJudges(client, couple.id);
});

/// All custom judges available to the couple (own + adopted).
/// Custom judges active for battle (own with is_active_for_battle + adopted).
final availableCustomJudgesProvider =
    FutureProvider<List<CustomJudge>>((ref) async {
  final mine = await ref.watch(myCustomJudgesProvider.future);
  final adopted = await ref.watch(adoptedJudgesProvider.future);
  // Only include own judges that are toggled for battle
  final activeMine = mine.where((j) => j.isActiveForBattle).toList();
  return [...activeMine, ...adopted];
});

/// Marketplace judges (with optional search query).
final marketplaceJudgesProvider =
    FutureProvider.family<List<CustomJudge>, String?>((ref, query) async {
  final client = ref.read(supabaseClientProvider);
  return CustomJudgeService.getMarketplaceJudges(client, searchQuery: query);
});

/// Top trending custom judges.
final trendingJudgesProvider = FutureProvider<List<CustomJudge>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  return CustomJudgeService.getTrendingJudges(client);
});
