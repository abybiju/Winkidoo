import 'package:supabase_flutter/supabase_flutter.dart';

/// Listens to Supabase Realtime for battle_messages and the surprise row for a given surprise.
/// When messages change, [onMessageChanged] is called so the UI can refetch the message list.
/// When the surprise row changes (e.g. battle_status → resolved), [onSurpriseChanged] is called
/// with the payload so the UI can invalidate providers and auto-navigate to reveal.
class BattleRealtimeService {
  BattleRealtimeService(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  String? _subscribedSurpriseId;

  void subscribe(
    String surpriseId,
    void Function() onMessageChanged, {
    void Function(PostgresChangePayload payload)? onSurpriseChanged,
  }) {
    if (_subscribedSurpriseId == surpriseId) return;
    _channel?.unsubscribe();
    _subscribedSurpriseId = surpriseId;

    var ch = _client
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
        );

    if (onSurpriseChanged != null) {
      ch = ch.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'surprises',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: surpriseId,
        ),
        callback: onSurpriseChanged,
      );
    }

    _channel = ch.subscribe();
  }

  void dispose() {
    _channel?.unsubscribe();
    _channel = null;
    _subscribedSurpriseId = null;
  }
}
