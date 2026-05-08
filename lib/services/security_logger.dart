import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Logs security-relevant events to Supabase for monitoring.
/// In debug mode, also prints to console.
/// Falls back silently on errors — logging must never break the app.
class SecurityLogger {
  SecurityLogger._();

  static const _table = 'security_logs';

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> authSuccess(String email, String method) async {
    await _log('auth_success', {'email': _mask(email), 'method': method});
  }

  static Future<void> authFailure(String email, String method, String reason) async {
    await _log('auth_failure', {
      'email': _mask(email),
      'method': method,
      'reason': reason,
    });
  }

  static Future<void> rateLimited(String email, String action) async {
    await _log('rate_limited', {'email': _mask(email), 'action': action});
  }

  static Future<void> apiError(String service, String operation, String error) async {
    await _log('api_error', {
      'service': service,
      'operation': operation,
      'error': error.length > 200 ? error.substring(0, 200) : error,
    });
  }

  static Future<void> suspiciousActivity(String description, Map<String, dynamic> context) async {
    await _log('suspicious', {'description': description, ...context});
  }

  static Future<void> _log(String eventType, Map<String, dynamic> details) async {
    if (kDebugMode) {
      debugPrint('SecurityLog[$eventType]: $details');
    }
    try {
      final userId = _client.auth.currentUser?.id;
      await _client.from(_table).insert({
        'event_type': eventType,
        'user_id': userId,
        'details': details,
      });
    } catch (_) {
      // Never let logging break the app
    }
  }

  /// Masks email for logs: "ab***@gmail.com"
  static String _mask(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].length < 2) return '***';
    return '${parts[0].substring(0, 2)}***@${parts[1]}';
  }
}
