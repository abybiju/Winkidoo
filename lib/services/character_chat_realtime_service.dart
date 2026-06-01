import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/models/character_chat_message.dart';

/// A peer currently typing in the room (from presence).
class TypingUser {
  const TypingUser({required this.uid, required this.name});
  final String uid;
  final String name;
}

/// One Supabase Realtime channel per open room carrying two primitives:
///  - Postgres changes on `character_chat_messages` → instant incremental
///    message delivery (INSERT + UPDATE both carry the authoritative row).
///  - Presence (`track`) → live "X is typing…" indicators.
///
/// Always call [dispose] from the widget's dispose() — it untracks presence
/// (so peers' typing indicator clears immediately) and unsubscribes.
class CharacterChatRealtimeService {
  CharacterChatRealtimeService(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  String? _subscribedRoomId;
  bool _subscribed = false;

  String _selfUid = '';
  String _selfName = 'Someone';

  void subscribe(
    String roomId, {
    required String selfUid,
    required String selfName,
    required void Function(CharacterChatMessage msg) onMessage,
    required void Function(List<TypingUser> others) onTypingChanged,
  }) {
    if (_subscribedRoomId == roomId && _channel != null) return;
    _channel?.unsubscribe();
    _subscribed = false;
    _subscribedRoomId = roomId;
    _selfUid = selfUid;
    _selfName = selfName;

    final ch = _client.channel('char_chat:$roomId');
    ch
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'character_chat_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_id',
          value: roomId,
        ),
        callback: (payload) {
          final rec = payload.newRecord;
          if (rec.isEmpty) return; // DELETE — nothing to apply
          onMessage(CharacterChatMessage.fromJson(rec));
        },
      )
      ..onPresenceSync((_) {
        final state = ch.presenceState();
        final typers = <TypingUser>[];
        for (final entry in state) {
          for (final p in entry.presences) {
            final pl = p.payload;
            if (pl['typing'] == true && pl['uid'] != _selfUid) {
              typers.add(TypingUser(
                uid: pl['uid'] as String? ?? '',
                name: pl['name'] as String? ?? 'Someone',
              ));
            }
          }
        }
        onTypingChanged(typers);
      })
      ..subscribe((status, _) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _subscribed = true;
          await ch.track({
            'uid': _selfUid,
            'name': _selfName,
            'typing': false,
          });
        }
      });

    _channel = ch;
  }

  /// Refreshes the display name peers see for me (e.g. once room members
  /// load with the authoritative name). Re-tracks with typing reset to false.
  Future<void> updateSelfName(String name) async {
    if (name == _selfName) return;
    _selfName = name;
    if (_subscribed && _channel != null) {
      await _channel!.track({
        'uid': _selfUid,
        'name': _selfName,
        'typing': false,
      });
    }
  }

  /// Updates my typing state for peers. `track` replaces the whole payload,
  /// so we always send the full {uid,name,typing} map.
  Future<void> setTyping(bool typing) async {
    if (!_subscribed || _channel == null) return;
    await _channel!.track({
      'uid': _selfUid,
      'name': _selfName,
      'typing': typing,
    });
  }

  Future<void> dispose() async {
    final ch = _channel;
    if (ch != null) {
      try {
        await ch.untrack();
      } catch (_) {}
      await ch.unsubscribe();
    }
    _channel = null;
    _subscribedRoomId = null;
    _subscribed = false;
  }
}
