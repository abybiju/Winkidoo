import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/app_notification.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

final notificationsListProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final data = await client
      .from('notifications')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .limit(100);

  return (data as List).map((json) {
    return AppNotification.fromJson(json as Map<String, dynamic>);
  }).toList();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsListProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

final notificationsNotifierProvider =
    AsyncNotifierProvider<NotificationsNotifier, void>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> markAsRead(String notificationId) async {
    final client = ref.read(supabaseClientProvider);
    await client
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
    ref.invalidate(notificationsListProvider);
  }

  Future<void> markAllAsRead() async {
    final client = ref.read(supabaseClientProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false);
    ref.invalidate(notificationsListProvider);
  }
}
