import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/models/winks_balance.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
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

/// Effective free attempts per day: Wink+ (or forceWinkPlusForTesting) gets more, else free tier.
final effectiveFreeAttemptsPerDayProvider = Provider<int>((ref) {
  final isWinkPlus = ref.watch(effectiveWinkPlusProvider);
  return isWinkPlus
      ? AppConstants.winkPlusFreeAttemptsPerDay
      : AppConstants.freeAttemptsPerDay;
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

/// Spends [amount] Winks, records a [type] transaction with [description].
/// Returns true if balance was sufficient and spend succeeded.
/// Call from widgets with their ref (Ref/WidgetRef); only used from UI.
Future<bool> spendWinks(
  dynamic ref,
  int amount, {
  required String type,
  required String description,
}) async {
  final r = ref as Ref;
  if (amount <= 0) return false;
  final client = r.read(supabaseClientProvider);
  final user = r.read(currentUserProvider);
  if (user == null) return false;

  final balance = await r.read(winksBalanceProvider.future);
  if (balance == null || balance.balance < amount) return false;

  try {
    await client.from('winks_balance').update({
      'balance': balance.balance - amount,
      'last_updated': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', user.id);

    await client.from('transactions').insert({
      'user_id': user.id,
      'amount': -amount,
      'type': type,
      'description': description,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    r.invalidate(winksBalanceProvider);
    return true;
  } catch (_) {
    return false;
  }
}
