import 'package:flutter/foundation.dart';

/// In-memory rate limiter for authentication actions.
/// Tracks attempts per key (email) with configurable windows and limits.
/// Resets on app restart — server-side rate limiting in Supabase provides
/// the durable layer; this blocks obvious abuse client-side.
class AuthRateLimiter {
  AuthRateLimiter._();

  static const int maxLoginAttempts = 5;
  static const int maxSignUpAttempts = 3;
  static const int maxResetAttempts = 3;
  static const Duration loginWindow = Duration(minutes: 15);
  static const Duration signUpWindow = Duration(minutes: 30);
  static const Duration resetWindow = Duration(hours: 1);

  static final Map<String, List<DateTime>> _loginAttempts = {};
  static final Map<String, List<DateTime>> _signUpAttempts = {};
  static final Map<String, List<DateTime>> _resetAttempts = {};

  static bool canAttemptLogin(String email) {
    if (kDebugMode) return true;
    return _canAttempt(_loginAttempts, email, maxLoginAttempts, loginWindow);
  }

  static bool canAttemptSignUp(String email) {
    if (kDebugMode) return true;
    return _canAttempt(_signUpAttempts, email, maxSignUpAttempts, signUpWindow);
  }

  static bool canAttemptReset(String email) {
    if (kDebugMode) return true;
    return _canAttempt(_resetAttempts, email, maxResetAttempts, resetWindow);
  }

  static void recordLoginAttempt(String email) =>
      _record(_loginAttempts, email);

  static void recordSignUpAttempt(String email) =>
      _record(_signUpAttempts, email);

  static void recordResetAttempt(String email) =>
      _record(_resetAttempts, email);

  /// Returns seconds until the next attempt is allowed, or 0 if allowed now.
  static int secondsUntilLoginAllowed(String email) =>
      _secondsUntil(_loginAttempts, email, maxLoginAttempts, loginWindow);

  static int secondsUntilResetAllowed(String email) =>
      _secondsUntil(_resetAttempts, email, maxResetAttempts, resetWindow);

  static bool _canAttempt(
    Map<String, List<DateTime>> store,
    String key,
    int max,
    Duration window,
  ) {
    _prune(store, key, window);
    final attempts = store[key];
    return attempts == null || attempts.length < max;
  }

  static int _secondsUntil(
    Map<String, List<DateTime>> store,
    String key,
    int max,
    Duration window,
  ) {
    _prune(store, key, window);
    final attempts = store[key];
    if (attempts == null || attempts.length < max) return 0;
    final oldest = attempts.first;
    final unlocksAt = oldest.add(window);
    final remaining = unlocksAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  static void _record(Map<String, List<DateTime>> store, String key) {
    store.putIfAbsent(key, () => []);
    store[key]!.add(DateTime.now());
  }

  static void _prune(
    Map<String, List<DateTime>> store,
    String key,
    Duration window,
  ) {
    final attempts = store[key];
    if (attempts == null) return;
    final cutoff = DateTime.now().subtract(window);
    attempts.removeWhere((t) => t.isBefore(cutoff));
    if (attempts.isEmpty) store.remove(key);
  }
}
