import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Client for the scene-director Edge Function. The function is the sole
/// authority on Director/castmate turns — this wrapper just pokes it.
///
/// `tick` is fire-and-forget and debounced: every member's client ticks after
/// every send, and the server's CAS turn-claim collapses the burst to exactly
/// one action, so a lost tick costs nothing (the next message re-ticks).
class SceneDirectorClient {
  SceneDirectorClient(this._client);

  final SupabaseClient _client;
  Timer? _tickDebounce;

  Future<Map<String, dynamic>> start(String roomId) =>
      _invoke('start', roomId);

  Future<Map<String, dynamic>> endScene(String roomId) =>
      _invoke('end_scene', roomId);

  /// Debounced fire-and-forget tick (2s) — never throws, never blocks send.
  void tick(String roomId) {
    _tickDebounce?.cancel();
    _tickDebounce = Timer(const Duration(seconds: 2), () {
      _invoke('tick', roomId).catchError((Object e) {
        debugPrint('SceneDirectorClient.tick: $e');
        return <String, dynamic>{};
      });
    });
  }

  Future<Map<String, dynamic>> _invoke(String action, String roomId) async {
    final response = await _client.functions.invoke(
      'scene-director',
      body: {'action': action, 'room_id': roomId},
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  void dispose() {
    _tickDebounce?.cancel();
  }
}
