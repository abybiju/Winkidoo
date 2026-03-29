import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/models/mini_game.dart';
import 'package:winkidoo/services/ai_judge_service.dart';
import 'package:winkidoo/services/encryption_service.dart';
import 'package:winkidoo/services/judge_memory_service.dart';

/// CRUD + orchestration for Couple Mini-Games.
class MiniGameService {
  /// Fetches today's game or generates one. One game per couple per day.
  static Future<MiniGame?> getOrCreateTodaysGame(
    SupabaseClient client,
    String coupleId,
    String apiKey, {
    String? packId,
    String? packPromptHint,
    String? packPersonaPromptOverride,
  }) async {
    try {
      await _expireStale(client, coupleId);

      final today = _todayString();

      final existing = await client
          .from('daily_mini_games')
          .select()
          .eq('couple_id', coupleId)
          .eq('game_date', today)
          .maybeSingle();

      if (existing != null) return MiniGame.fromJson(existing);

      // Determine game type via deterministic rotation
      final dayOfYear = DateTime.now()
          .difference(DateTime(DateTime.now().year, 1, 1))
          .inDays;
      final gameType = AppConstants.miniGameRotation[
          dayOfYear % AppConstants.miniGameRotation.length];

      // Persona rotation (offset by 2 from dare rotation so they differ)
      final persona = AppConstants.darePersonaRotation[
          (dayOfYear + 2) % AppConstants.darePersonaRotation.length];

      // Fetch judge memories for Love Trivia personalization
      final memories =
          await JudgeMemoryService.getMemories(client, coupleId, persona);

      // Generate game via AI
      final judge = AiJudgeService(apiKey: apiKey);
      final result = await judge.generateMiniGame(
        persona: persona,
        gameType: gameType,
        judgeMemories: memories,
        packPromptHint: packPromptHint,
        personaPromptOverride: packPersonaPromptOverride,
      );

      final row = await client
          .from('daily_mini_games')
          .upsert(
            {
              'couple_id': coupleId,
              'game_date': today,
              'game_type': gameType,
              'judge_persona': persona,
              'game_prompt': result.prompt,
              'game_options': result.options,
              'status': 'pending',
              if (packId != null) 'pack_id': packId,
            },
            onConflict: 'couple_id,game_date',
          )
          .select()
          .single();

      return MiniGame.fromJson(row);
    } catch (e) {
      debugPrint('MiniGameService.getOrCreateTodaysGame: $e');
      return null;
    }
  }

  /// Submit the current user's response.
  static Future<MiniGame?> submitResponse(
    SupabaseClient client, {
    required String gameId,
    required String coupleId,
    required String userId,
    required String userAId,
    required String plainContent,
  }) async {
    try {
      final encrypted =
          await EncryptionService.encrypt(plainContent, coupleId: coupleId);

      final isUserA = userId == userAId;
      final now = DateTime.now().toUtc().toIso8601String();

      final current = await client
          .from('daily_mini_games')
          .select()
          .eq('id', gameId)
          .single();
      final game = MiniGame.fromJson(current);

      final partnerDone = isUserA
          ? game.userBSubmittedAt != null
          : game.userASubmittedAt != null;
      final newStatus = partnerDone ? 'complete' : 'partial';

      final updates = <String, dynamic>{'status': newStatus};
      if (isUserA) {
        updates['user_a_response'] = encrypted;
        updates['user_a_submitted_at'] = now;
      } else {
        updates['user_b_response'] = encrypted;
        updates['user_b_submitted_at'] = now;
      }

      final row = await client
          .from('daily_mini_games')
          .update(updates)
          .eq('id', gameId)
          .select()
          .single();

      return MiniGame.fromJson(row);
    } catch (e) {
      debugPrint('MiniGameService.submitResponse: $e');
      return null;
    }
  }

  /// Grades a completed game via AI.
  static Future<MiniGame?> gradeGame(
    SupabaseClient client,
    String apiKey,
    MiniGame game,
    String coupleId, {
    String? packPersonaPromptOverride,
  }) async {
    try {
      final responseA = game.userAResponse != null
          ? await EncryptionService.decrypt(game.userAResponse!,
              coupleId: coupleId)
          : '';
      final responseB = game.userBResponse != null
          ? await EncryptionService.decrypt(game.userBResponse!,
              coupleId: coupleId)
          : '';

      final judge = AiJudgeService(apiKey: apiKey);
      final grade = await judge.gradeMiniGame(
        persona: game.judgePersona,
        gameType: game.gameType,
        gamePrompt: game.gamePrompt,
        responseA: responseA,
        responseB: responseB,
        personaPromptOverride: packPersonaPromptOverride,
      );

      final now = DateTime.now().toUtc().toIso8601String();
      final row = await client
          .from('daily_mini_games')
          .update({
            'grade_commentary': grade.commentary,
            'grade_score': grade.score,
            'grade_emoji': grade.emoji,
            'graded_at': now,
            'status': 'graded',
          })
          .eq('id', game.id)
          .select()
          .single();

      return MiniGame.fromJson(row);
    } catch (e) {
      debugPrint('MiniGameService.gradeGame: $e');
      return null;
    }
  }

  static Future<void> _expireStale(
    SupabaseClient client,
    String coupleId,
  ) async {
    try {
      await client
          .from('daily_mini_games')
          .update({'status': 'expired'})
          .eq('couple_id', coupleId)
          .inFilter('status', ['pending', 'partial'])
          .lt('expires_at', DateTime.now().toUtc().toIso8601String());
    } catch (e) {
      debugPrint('MiniGameService._expireStale: $e');
    }
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
