import 'package:supabase_flutter/supabase_flutter.dart';

/// Deletes the current user's account by invoking the `delete-account`
/// Edge Function (service-role required), then signs out locally.
///
/// The Edge Function preserves a partner's shared vault by transferring
/// couple ownership before removing the auth user. See
/// `supabase/functions/delete-account/index.ts`.
class AccountDeletionService {
  AccountDeletionService(this._client);

  final SupabaseClient _client;

  /// Permanently deletes the signed-in user's account.
  ///
  /// Throws [AccountDeletionException] on failure so callers can surface a
  /// message. On success the local session is cleared.
  Future<void> deleteAccount() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AccountDeletionException('You are not signed in.');
    }

    try {
      final res = await _client.functions.invoke(
        'delete-account',
        method: HttpMethod.post,
      );

      final status = res.status ?? 500;
      if (status < 200 || status >= 300) {
        final data = res.data;
        final msg = (data is Map && data['error'] is String)
            ? data['error'] as String
            : 'Account deletion failed (status $status).';
        throw AccountDeletionException(msg);
      }
    } on FunctionException catch (e) {
      final details = e.details;
      final msg = (details is Map && details['error'] is String)
          ? details['error'] as String
          : 'Account deletion failed. Please try again or contact support.';
      throw AccountDeletionException(msg);
    } on AccountDeletionException {
      rethrow;
    } catch (_) {
      throw const AccountDeletionException(
        'Account deletion failed. Please try again or contact support.',
      );
    }

    // Clear the now-invalid local session. The user row is already gone.
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Session is already invalid server-side; ignore sign-out errors.
    }
  }
}

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.message);
  final String message;

  @override
  String toString() => message;
}
