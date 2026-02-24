import 'package:supabase_flutter/supabase_flutter.dart';

/// Listens to Supabase Realtime for surprises table and invalidation.
/// Call [subscribe] with a callback when surprises change (e.g. ref.invalidate(surprisesListProvider)).
class RealtimeService {
  RealtimeService(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;

  void subscribe(String coupleId, void Function() onSurprisesChanged) {
    _channel?.unsubscribe();
    _channel = _client
        .channel('surprises:$coupleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'surprises',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (payload) {
            onSurprisesChanged();
          },
        )
        .subscribe();
  }

  void dispose() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
