import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/winks_balance.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

final winksBalanceProvider = FutureProvider<WinksBalance?>((ref) async {
  try {
    final client = ref.watch(supabaseClientProvider);
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    var res = await client
        .from('winks_balance')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (res == null || res is! Map<String, dynamic>) {
      await client.from('winks_balance').insert({
        'user_id': user.id,
        'balance': 10,
        'last_updated': DateTime.now().toUtc().toIso8601String(),
      });
      final raw = await client
          .from('winks_balance')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (raw is Map<String, dynamic>) return WinksBalance.fromJson(raw);
      return null;
    }
    return WinksBalance.fromJson(res);
  } catch (_) {
    return null;
  }
});

final todayAttemptsCountProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc().toIso8601String();

  final res = await client
      .from('attempts')
      .select('id')
      .eq('user_id', user.id)
      .gte('created_at', startOfDay)
      .lte('created_at', endOfDay);

  return (res as List).length;
});
