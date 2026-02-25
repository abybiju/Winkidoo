import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/couple.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

class CoupleNotifier extends AsyncNotifier<Couple?> {
  @override
  Future<Couple?> build() async {
    try {
      final client = ref.watch(supabaseClientProvider);
      final user = ref.watch(currentUserProvider);
      if (user == null) return null;

      // Fetch ALL couple rows where this user is a member (handles duplicates)
      final rows = await client
          .from('couples')
          .select()
          .or('user_a_id.eq.${user.id},user_b_id.eq.${user.id}')
          .order('created_at', ascending: false);

      final list = rows is List ? rows : <dynamic>[];
      if (list.isEmpty) return null;

      // Prefer a linked couple (user_b_id is set) over an unlinked one
      Map<String, dynamic>? best;
      for (final row in list) {
        if (row is Map<String, dynamic>) {
          if (row['user_b_id'] != null) {
            best = row;
            break;
          }
          best ??= row;
        }
      }

      if (best != null) return Couple.fromJson(best);
      return null;
    } catch (e, st) {
      debugPrint('coupleProvider: $e');
      debugPrint('$st');
      return null;
    }
  }

  void setCouple(Couple c) {
    state = AsyncData(c);
  }
}

final coupleProvider =
    AsyncNotifierProvider<CoupleNotifier, Couple?>(() => CoupleNotifier());
