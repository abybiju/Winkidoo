import 'package:supabase_flutter/supabase_flutter.dart';

/// Listens to Supabase Realtime for battle_messages for a given surprise.
/// When a new message is inserted (or updated), [onMessageChanged] is called
/// so the UI can refetch the message list.
class BattleRealtimeService {
  BattleRealtimeService(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  String? _subscribedSurpriseId;

  void subscribe(String surpriseId, void Function() onMessageChanged) {
    if (_subscribedSurpriseId == surpriseId) return;
    _channel?.unsubscribe();
    _subscribedSurpriseId = surpriseId;

    _channel = _client
        .channel('battle:$surpriseId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'battle_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'surprise_id',
            value: surpriseId,
          ),
          callback: (_) => onMessageChanged(),
        )
        .subscribe();
  }

  void dispose() {
    _channel?.unsubscribe();
    _channel = null;
    _subscribedSurpriseId = null;
  }
}
