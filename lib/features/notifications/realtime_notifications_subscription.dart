import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/notification_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/notification_realtime_service.dart';

class RealtimeNotificationsSubscription extends ConsumerStatefulWidget {
  const RealtimeNotificationsSubscription({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<RealtimeNotificationsSubscription> createState() =>
      _RealtimeNotificationsSubscriptionState();
}

class _RealtimeNotificationsSubscriptionState
    extends ConsumerState<RealtimeNotificationsSubscription> {
  NotificationRealtimeService? _realtime;
  String? _subscribedUserId;

  @override
  void dispose() {
    _realtime?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (prev, next) {
      next.whenData((session) {
        final userId = session?.user.id;
        if (userId != null && userId != _subscribedUserId) {
          _subscribedUserId = userId;
          _realtime?.dispose();
          final client = ref.read(supabaseClientProvider);
          _realtime = NotificationRealtimeService(client);
          _realtime!.subscribe(userId, () {
            ref.invalidate(notificationsListProvider);
          });
        } else if (userId == null) {
          _subscribedUserId = null;
          _realtime?.dispose();
          _realtime = null;
        }
      });
    });

    return widget.child;
  }
}
