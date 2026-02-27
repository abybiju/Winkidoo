import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registers the current device's FCM token with Supabase for server-authoritative push.
/// Call after login and on token refresh. No client-triggered send logic.
class PushService {
  PushService._();

  static String get _platform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'web';
    }
  }

  /// Get FCM token and upsert into user_push_tokens. Call when session is available.
  static Future<void> register(SupabaseClient client, String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await client.from('user_push_tokens').upsert(
            {
              'user_id': userId,
              'push_token': token,
              'push_platform': _platform,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            onConflict: 'push_token',
          );
    } catch (_) {
      // Ignore: token may be unavailable (e.g. web without permission)
    }
  }

  /// Call once to re-register when FCM token refreshes. Uses current session user.
  static void onTokenRefresh(SupabaseClient client) {
    FirebaseMessaging.instance.onTokenRefresh.listen((_) async {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      await register(client, userId);
    });
  }
}
