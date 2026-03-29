import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/judge_pack.dart';
import 'package:winkidoo/models/pack_judge_override.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/pack_service.dart';

/// All currently active packs (for browse/selection UI).
final activePacksProvider = FutureProvider<List<JudgePack>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  return PackService.getActivePacks(client);
});

/// The couple's currently active pack (nullable).
final coupleActivePackProvider = FutureProvider<JudgePack?>((ref) async {
  final couple = ref.watch(coupleProvider).value;
  if (couple == null) return null;

  final client = ref.read(supabaseClientProvider);
  final packId = await PackService.getCoupleActivePackId(client, couple.id);
  if (packId == null) return null;

  return PackService.getPackById(client, packId);
});

/// Judge overrides for the couple's active pack, keyed by persona ID.
/// Empty map when no pack is active.
final activePackJudgeOverridesProvider =
    FutureProvider<Map<String, PackJudgeOverride>>((ref) async {
  final pack = ref.watch(coupleActivePackProvider).value;
  if (pack == null) return {};

  final client = ref.read(supabaseClientProvider);
  return PackService.getPackJudgeOverrides(client, pack.id);
});

/// Judge overrides for a specific pack (for pack detail screen).
final packJudgeOverridesProvider =
    FutureProvider.family<Map<String, PackJudgeOverride>, String>(
        (ref, packId) async {
  final client = ref.read(supabaseClientProvider);
  return PackService.getPackJudgeOverrides(client, packId);
});

/// Pack by slug (for pack detail screen).
final packBySlugProvider =
    FutureProvider.family<JudgePack?, String>((ref, slug) async {
  final client = ref.read(supabaseClientProvider);
  return PackService.getPackBySlug(client, slug);
});
