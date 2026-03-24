import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/leaderboard_entry.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/leaderboard_service.dart';

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final client = ref.read(supabaseClientProvider);
  return LeaderboardService.getLeaderboard(client);
});
