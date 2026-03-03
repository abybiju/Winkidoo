import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateProvider = StreamProvider<Session?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((data) {
    return data.session;
  });
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value?.user;
});
