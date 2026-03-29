import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/models/daily_dare.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/battle_pass_service.dart';
import 'package:winkidoo/services/daily_activity_service.dart';
import 'package:winkidoo/services/daily_dare_service.dart';
import 'package:winkidoo/services/dare_realtime_service.dart';
import 'package:winkidoo/services/xp_service.dart';

const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

/// The phase of today's dare from the current user's perspective.
enum DarePhase {
  loading,
  generating,
  pending,
  myTurn,
  waitingForPartner,
  grading,
  graded,
  expired,
  unavailable,
  error,
}

class DailyDareState {
  const DailyDareState({
    required this.phase,
    this.dare,
  });

  final DarePhase phase;
  final DailyDare? dare;

  static const loading = DailyDareState(phase: DarePhase.loading);
  static const unavailable = DailyDareState(phase: DarePhase.unavailable);
  static const error = DailyDareState(phase: DarePhase.error);
}

class DailyDareNotifier extends AsyncNotifier<DailyDareState> {
  DareRealtimeService? _realtimeService;

  @override
  Future<DailyDareState> build() async {
    try {
      final couple = ref.watch(coupleProvider).value;
      final user = ref.watch(currentUserProvider);
      if (couple == null || user == null || !couple.isLinked) {
        return DailyDareState.unavailable;
      }

      final client = ref.read(supabaseClientProvider);
      const apiKey = _geminiApiKey;

      // Set up realtime subscription for partner's dare updates
      _realtimeService?.dispose();
      _realtimeService = DareRealtimeService(client);
      _realtimeService!.subscribe(couple.id, () => ref.invalidateSelf());
      ref.onDispose(() => _realtimeService?.dispose());

      final dare = await DailyDareService.getOrCreateTodaysDare(
        client,
        couple.id,
        apiKey,
      );

      if (dare == null) return DailyDareState.error;

      final phase = _resolvePhase(dare, user.id, couple.userAId);
      return DailyDareState(phase: phase, dare: dare);
    } catch (e) {
      debugPrint('DailyDareNotifier.build: $e');
      return DailyDareState.error;
    }
  }

  /// Submit the current user's response and handle downstream effects.
  Future<void> submitResponse(String content, {String type = 'text'}) async {
    final couple = ref.read(coupleProvider).value;
    final user = ref.read(currentUserProvider);
    final currentDare = state.value?.dare;
    if (couple == null || user == null || currentDare == null) return;

    final client = ref.read(supabaseClientProvider);

    state = const AsyncData(
      DailyDareState(phase: DarePhase.loading),
    );

    final updated = await DailyDareService.submitResponse(
      client,
      dareId: currentDare.id,
      coupleId: couple.id,
      userId: user.id,
      userAId: couple.userAId,
      plainContent: content,
      responseType: type,
    );

    if (updated == null) {
      state = AsyncData(
        DailyDareState(phase: DarePhase.error, dare: currentDare),
      );
      return;
    }

    // If both submitted, trigger grading
    if (updated.status == 'complete') {
      state = AsyncData(
        DailyDareState(phase: DarePhase.grading, dare: updated),
      );

      const apiKey = _geminiApiKey;
      final graded = await DailyDareService.gradeDare(
        client,
        apiKey,
        updated,
        couple.id,
      );

      // Award rewards after both complete
      await _awardRewards(client, couple.id);

      if (graded != null) {
        state = AsyncData(
          DailyDareState(phase: DarePhase.graded, dare: graded),
        );
      } else {
        // Grading failed — still show as complete
        state = AsyncData(
          DailyDareState(phase: DarePhase.graded, dare: updated),
        );
      }
      return;
    }

    // Only one submitted so far
    state = AsyncData(
      DailyDareState(
        phase: DarePhase.waitingForPartner,
        dare: updated,
      ),
    );
  }

  /// Awards XP, battle pass points, and logs daily activity for streak.
  Future<void> _awardRewards(dynamic client, String coupleId) async {
    try {
      // Streak tracking
      await DailyActivityService(client).logActivity(
        coupleId: coupleId,
        activityType: AppConstants.activityDareCompleted,
      );
      // XP
      await XpService.awardXp(client, coupleId, AppConstants.xpPerDareCompleted);
      // Battle Pass
      await BattlePassService.awardPoints(
          client, coupleId, BattlePassService.pointsDareCompleted);
    } catch (e) {
      debugPrint('DailyDareNotifier._awardRewards: $e');
    }
  }

  /// Refresh dare state (called after realtime notification).
  Future<void> refreshDare() async {
    ref.invalidateSelf();
  }

  DarePhase _resolvePhase(DailyDare dare, String userId, String userAId) {
    if (dare.isExpired) return DarePhase.expired;
    if (dare.isGraded) return DarePhase.graded;
    if (dare.status == 'complete') return DarePhase.grading;

    final myDone = dare.myResponseSubmitted(userId, userAId);
    final partnerDone = dare.partnerResponseSubmitted(userId, userAId);

    if (myDone && !partnerDone) return DarePhase.waitingForPartner;
    if (!myDone && partnerDone) return DarePhase.myTurn;
    return DarePhase.pending;
  }
}

final dailyDareProvider =
    AsyncNotifierProvider<DailyDareNotifier, DailyDareState>(
        () => DailyDareNotifier());
