import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/models/mini_game.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/battle_pass_service.dart';
import 'package:winkidoo/services/daily_activity_service.dart';
import 'package:winkidoo/services/mini_game_realtime_service.dart';
import 'package:winkidoo/services/mini_game_service.dart';
import 'package:winkidoo/services/xp_service.dart';

const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

enum MiniGamePhase {
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

class MiniGameState {
  const MiniGameState({required this.phase, this.game});

  final MiniGamePhase phase;
  final MiniGame? game;

  static const loading = MiniGameState(phase: MiniGamePhase.loading);
  static const unavailable = MiniGameState(phase: MiniGamePhase.unavailable);
  static const error = MiniGameState(phase: MiniGamePhase.error);
}

class MiniGameNotifier extends AsyncNotifier<MiniGameState> {
  MiniGameRealtimeService? _realtimeService;

  @override
  Future<MiniGameState> build() async {
    try {
      final couple = ref.watch(coupleProvider).value;
      final user = ref.watch(currentUserProvider);
      if (couple == null || user == null || !couple.isLinked) {
        return MiniGameState.unavailable;
      }

      final client = ref.read(supabaseClientProvider);
      const apiKey = _geminiApiKey;

      // Realtime subscription for partner updates on mini_games
      _realtimeService?.dispose();
      _realtimeService = MiniGameRealtimeService(client);
      // Reuse MiniGameRealtimeService pattern but for daily_mini_games table
      _realtimeService!.subscribe(couple.id, () => ref.invalidateSelf());
      ref.onDispose(() => _realtimeService?.dispose());

      final game = await MiniGameService.getOrCreateTodaysGame(
        client,
        couple.id,
        apiKey,
      );

      if (game == null) return MiniGameState.error;

      final phase = _resolvePhase(game, user.id, couple.userAId);
      return MiniGameState(phase: phase, game: game);
    } catch (e) {
      debugPrint('MiniGameNotifier.build: $e');
      return MiniGameState.error;
    }
  }

  Future<void> submitResponse(String content) async {
    final couple = ref.read(coupleProvider).value;
    final user = ref.read(currentUserProvider);
    final currentGame = state.value?.game;
    if (couple == null || user == null || currentGame == null) return;

    final client = ref.read(supabaseClientProvider);

    state = const AsyncData(MiniGameState(phase: MiniGamePhase.loading));

    final updated = await MiniGameService.submitResponse(
      client,
      gameId: currentGame.id,
      coupleId: couple.id,
      userId: user.id,
      userAId: couple.userAId,
      plainContent: content,
    );

    if (updated == null) {
      state = AsyncData(MiniGameState(phase: MiniGamePhase.error, game: currentGame));
      return;
    }

    if (updated.status == 'complete') {
      state = AsyncData(MiniGameState(phase: MiniGamePhase.grading, game: updated));

      const apiKey = _geminiApiKey;
      final graded = await MiniGameService.gradeGame(
        client,
        apiKey,
        updated,
        couple.id,
      );

      await _awardRewards(client, couple.id);

      state = AsyncData(MiniGameState(
        phase: MiniGamePhase.graded,
        game: graded ?? updated,
      ));
      return;
    }

    state = AsyncData(MiniGameState(
      phase: MiniGamePhase.waitingForPartner,
      game: updated,
    ));
  }

  Future<void> _awardRewards(dynamic client, String coupleId) async {
    try {
      await DailyActivityService(client).logActivity(
        coupleId: coupleId,
        activityType: AppConstants.activityMiniGameCompleted,
      );
      await XpService.awardXp(client, coupleId, AppConstants.xpPerMiniGameCompleted);
      await BattlePassService.awardPoints(
          client, coupleId, BattlePassService.pointsMiniGameCompleted);
    } catch (e) {
      debugPrint('MiniGameNotifier._awardRewards: $e');
    }
  }

  MiniGamePhase _resolvePhase(MiniGame game, String userId, String userAId) {
    if (game.isExpired) return MiniGamePhase.expired;
    if (game.isGraded) return MiniGamePhase.graded;
    if (game.status == 'complete') return MiniGamePhase.grading;

    final myDone = game.myResponseSubmitted(userId, userAId);
    final partnerDone = game.partnerResponseSubmitted(userId, userAId);

    if (myDone && !partnerDone) return MiniGamePhase.waitingForPartner;
    if (!myDone && partnerDone) return MiniGamePhase.myTurn;
    return MiniGamePhase.pending;
  }
}

final miniGameProvider =
    AsyncNotifierProvider<MiniGameNotifier, MiniGameState>(
        () => MiniGameNotifier());
