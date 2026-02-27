import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/battle_message.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/battle_service.dart';

final battleServiceProvider = Provider<BattleService>((ref) {
  return BattleService(ref.watch(supabaseClientProvider));
});

final battleMessagesProvider =
    FutureProvider.family<List<BattleMessage>, String>((ref, surpriseId) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('battle_messages')
      .select()
      .eq('surprise_id', surpriseId)
      .order('created_at', ascending: true);

  final list = data is List ? data : (data != null ? [data] : <dynamic>[]);
  final results = <BattleMessage>[];
  for (final r in list) {
    if (r is Map<String, dynamic>) {
      try {
        results.add(BattleMessage.fromJson(r));
      } catch (_) {}
    }
  }
  return results;
});

/// True if this surprise has an active battle (messages exist and no verdict yet).
final hasActiveBattleProvider =
    FutureProvider.family<bool, String>((ref, surpriseId) async {
  final messages = await ref.watch(battleMessagesProvider(surpriseId).future);
  if (messages.isEmpty) return false;
  return !messages.any((m) => m.isVerdict);
});
