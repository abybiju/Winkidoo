import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/couple.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

final coupleProvider = FutureProvider<Couple?>((ref) async {
  try {
    final client = ref.watch(supabaseClientProvider);
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    final asMember = await client
        .from('couples')
        .select()
        .or('user_a_id.eq.${user.id},user_b_id.eq.${user.id}')
        .maybeSingle();

    if (asMember is Map<String, dynamic>) {
      return Couple.fromJson(asMember);
    }
    return null;
  } catch (e, st) {
    debugPrint('coupleProvider: $e');
    debugPrint('$st');
    return null;
  }
});
