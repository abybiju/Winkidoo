import 'package:supabase_flutter/supabase_flutter.dart';

/// Listens to Supabase Realtime for daily_dares table changes.
/// When the partner submits their response or grading completes,
/// [onDareChanged] fires so the UI can refresh.
class DareRealtimeService {
  DareRealtimeService(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  String? _subscribedCoupleId;

  void subscribe(String coupleId, void Function() onDareChanged) {
    if (_subscribedCoupleId == coupleId) return;
    _channel?.unsubscribe();
    _subscribedCoupleId = coupleId;

    _channel = _client
        .channel('dares:$coupleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'daily_dares',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (_) => onDareChanged(),
        )
        .subscribe();
  }

  void dispose() {
    _channel?.unsubscribe();
    _channel = null;
    _subscribedCoupleId = null;
  }
}
