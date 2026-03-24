import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/battle_pass_service.dart';

final battlePassProvider = FutureProvider<BattlePassProgress?>((ref) async {
  final couple = ref.watch(coupleProvider).value;
  if (couple == null) return null;
  final client = ref.read(supabaseClientProvider);
  return BattlePassService.getProgress(client, couple.id);
});
