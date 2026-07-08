import 'package:flutter/foundation.dart';
import 'package:winkidoo/services/security_logger.dart';

/// Client-side rate limiter for all API actions.
///
/// Each action type has its own bucket with configurable limits and windows.
/// Tracks attempts in-memory per key (user ID, email, or couple ID).
/// Server-side enforcement via Supabase provides the durable layer;
/// this blocks obvious client-side abuse and reduces wasted API calls.
class ApiRateLimiter {
  ApiRateLimiter._();

  /// Bucket definitions: action → (maxAttempts, windowDuration).
  static final Map<String, _BucketConfig> _buckets = {
    'ai_battle_chat': const _BucketConfig(20, const Duration(minutes: 5)),
    'ai_dare_generate': const _BucketConfig(5, const Duration(minutes: 10)),
    'ai_dare_grade': const _BucketConfig(10, const Duration(minutes: 10)),
    'ai_mini_game': const _BucketConfig(5, const Duration(minutes: 10)),
    'ai_mini_game_grade': const _BucketConfig(10, const Duration(minutes: 10)),
    'ai_character_chat': const _BucketConfig(30, const Duration(minutes: 5)),
    'ai_custom_judge': const _BucketConfig(3, const Duration(hours: 1)),
    'ai_forensics': const _BucketConfig(3, const Duration(hours: 1)),
    'ai_future_letter': const _BucketConfig(5, const Duration(minutes: 30)),
    'ai_judge_audition': const _BucketConfig(10, const Duration(minutes: 10)),
    'friend_search': const _BucketConfig(15, const Duration(minutes: 5)),
    'friend_request': const _BucketConfig(10, const Duration(minutes: 10)),
    'couple_join': const _BucketConfig(5, const Duration(minutes: 15)),
    'surprise_create': const _BucketConfig(10, const Duration(minutes: 10)),
    'battle_start': const _BucketConfig(10, const Duration(minutes: 10)),
    'scene_message': const _BucketConfig(20, Duration(minutes: 5)),
    'scene_game_submit': const _BucketConfig(10, Duration(minutes: 5)),
    'scene_create': const _BucketConfig(3, Duration(minutes: 10)),
  };

  /// Per-action, per-key attempt timestamps.
  static final Map<String, Map<String, List<DateTime>>> _store = {};

  /// Burst detection: tracks rapid consecutive calls per action+key.
  static final Map<String, DateTime> _lastCallTime = {};
  static const Duration _burstThreshold = Duration(milliseconds: 500);
  static final Map<String, int> _burstCount = {};
  static const int _burstLimit = 5;

  /// Check if the action is allowed for the given key.
  /// Returns true if under the limit, false if rate-limited.
  static bool canProceed(String action, String key) {
    if (kDebugMode) return true;

    final config = _buckets[action];
    if (config == null) return true;

    _prune(action, key, config.window);
    final attempts = _store[action]?[key];
    return attempts == null || attempts.length < config.maxAttempts;
  }

  /// Record an attempt for the action+key. Returns false if this call
  /// triggers a burst detection (too many calls in rapid succession).
  static bool recordAttempt(String action, String key) {
    _store.putIfAbsent(action, () => {});
    _store[action]!.putIfAbsent(key, () => []);
    _store[action]![key]!.add(DateTime.now());

    return !_detectBurst(action, key);
  }

  /// Check and record in one call. Returns a [RateLimitResult].
  static RateLimitResult checkAndRecord(String action, String key) {
    if (kDebugMode) {
      return const RateLimitResult(allowed: true, waitSeconds: 0, burst: false);
    }

    if (!canProceed(action, key)) {
      final wait = secondsUntilAllowed(action, key);
      SecurityLogger.rateLimited(key, action);
      return RateLimitResult(allowed: false, waitSeconds: wait, burst: false);
    }

    final noBurst = recordAttempt(action, key);
    if (!noBurst) {
      SecurityLogger.suspiciousActivity(
        'Burst detected: $action',
        {'key': key, 'action': action},
      );
      return const RateLimitResult(allowed: false, waitSeconds: 2, burst: true);
    }

    return const RateLimitResult(allowed: true, waitSeconds: 0, burst: false);
  }

  /// Seconds until the next attempt is allowed.
  static int secondsUntilAllowed(String action, String key) {
    final config = _buckets[action];
    if (config == null) return 0;

    _prune(action, key, config.window);
    final attempts = _store[action]?[key];
    if (attempts == null || attempts.length < config.maxAttempts) return 0;

    final oldest = attempts.first;
    final unlocksAt = oldest.add(config.window);
    final remaining = unlocksAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Returns remaining attempts for the action+key.
  static int remainingAttempts(String action, String key) {
    if (kDebugMode) return 999;
    final config = _buckets[action];
    if (config == null) return 999;

    _prune(action, key, config.window);
    final attempts = _store[action]?[key];
    final used = attempts?.length ?? 0;
    return (config.maxAttempts - used).clamp(0, config.maxAttempts);
  }

  static bool _detectBurst(String action, String key) {
    final compositeKey = '$action:$key';
    final now = DateTime.now();
    final last = _lastCallTime[compositeKey];
    _lastCallTime[compositeKey] = now;

    if (last != null && now.difference(last) < _burstThreshold) {
      _burstCount[compositeKey] = (_burstCount[compositeKey] ?? 0) + 1;
      if (_burstCount[compositeKey]! >= _burstLimit) {
        _burstCount[compositeKey] = 0;
        return true;
      }
    } else {
      _burstCount[compositeKey] = 0;
    }
    return false;
  }

  static void _prune(String action, String key, Duration window) {
    final actionStore = _store[action];
    if (actionStore == null) return;
    final attempts = actionStore[key];
    if (attempts == null) return;
    final cutoff = DateTime.now().subtract(window);
    attempts.removeWhere((t) => t.isBefore(cutoff));
    if (attempts.isEmpty) actionStore.remove(key);
  }
}

class _BucketConfig {
  const _BucketConfig(this.maxAttempts, this.window);
  final int maxAttempts;
  final Duration window;
}

class RateLimitResult {
  const RateLimitResult({
    required this.allowed,
    required this.waitSeconds,
    required this.burst,
  });

  final bool allowed;
  final int waitSeconds;
  final bool burst;

  String get userMessage {
    if (burst) return 'Slow down! Please wait a moment before trying again.';
    if (!allowed) {
      final mins = (waitSeconds / 60).ceil();
      return mins > 1
          ? 'Too many requests. Try again in $mins minutes.'
          : 'Too many requests. Try again in a moment.';
    }
    return '';
  }
}
