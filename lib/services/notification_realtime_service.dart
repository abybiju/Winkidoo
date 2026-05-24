import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRealtimeService {
  NotificationRealtimeService(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  String? _subscribedUserId;

  void subscribe(String userId, void Function() onNotificationChanged) {
    if (_subscribedUserId == userId) return;
    _channel?.unsubscribe();
    _subscribedUserId = userId;

    _channel = _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => onNotificationChanged(),
        )
        .subscribe();
  }

  void dispose() {
    _channel?.unsubscribe();
    _channel = null;
    _subscribedUserId = null;
  }
}
