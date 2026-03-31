import 'package:supabase_flutter/supabase_flutter.dart';

/// Listens to Supabase Realtime for character_chat_messages in a room.
/// Subscribes to both INSERT (new messages) and UPDATE (transform completion).
class CharacterChatRealtimeService {
  CharacterChatRealtimeService(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  String? _subscribedRoomId;

  void subscribe(String roomId, void Function() onMessageChanged) {
    if (_subscribedRoomId == roomId) return;
    _channel?.unsubscribe();
    _subscribedRoomId = roomId;

    _channel = _client
        .channel('char_chat:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'character_chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (_) => onMessageChanged(),
        )
        .subscribe();
  }

  void dispose() {
    _channel?.unsubscribe();
    _channel = null;
    _subscribedRoomId = null;
  }
}
