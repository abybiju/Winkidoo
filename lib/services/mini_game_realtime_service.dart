import 'package:supabase_flutter/supabase_flutter.dart';

/// Listens to Supabase Realtime for daily_mini_games table changes.
class MiniGameRealtimeService {
  MiniGameRealtimeService(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  String? _subscribedCoupleId;

  void subscribe(String coupleId, void Function() onGameChanged) {
    if (_subscribedCoupleId == coupleId) return;
    _channel?.unsubscribe();
    _subscribedCoupleId = coupleId;

    _channel = _client
        .channel('minigames:$coupleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'daily_mini_games',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (_) => onGameChanged(),
        )
        .subscribe();
  }

  void dispose() {
    _channel?.unsubscribe();
    _channel = null;
    _subscribedCoupleId = null;
  }
}
