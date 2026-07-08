import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/models/scene_session.dart';

/// Live scene-session updates for ONE open room.
///
/// One channel per open room (`scene:$roomId`), subscribed only while the
/// chat screen for that room is mounted — deliberately per-room (not a single
/// global channel) so multi-room users get updates for whichever room they
/// have open. Always dispose() from the widget's dispose().
class SceneRealtimeService {
  SceneRealtimeService(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  String? _roomId;

  void subscribe({
    required String roomId,
    required void Function(SceneSession session) onSession,
  }) {
    if (_roomId == roomId && _channel != null) return;
    dispose();
    _roomId = roomId;
    _channel = _client
        .channel('scene:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'scene_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            if (payload.newRecord.isEmpty) return;
            onSession(SceneSession.fromJson(payload.newRecord));
          },
        )
        .subscribe();
  }

  void dispose() {
    final ch = _channel;
    _channel = null;
    _roomId = null;
    if (ch != null) {
      _client.removeChannel(ch);
    }
  }
}
