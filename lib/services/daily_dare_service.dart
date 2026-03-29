import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/models/daily_dare.dart';
import 'package:winkidoo/services/ai_judge_service.dart';
import 'package:winkidoo/services/encryption_service.dart';
import 'package:winkidoo/services/judge_memory_service.dart';

/// CRUD + orchestration for Daily Love Dares.
class DailyDareService {
  /// Fetches today's dare for the couple. If none exists, generates one via AI
  /// and inserts it. Returns the dare row.
  static Future<DailyDare?> getOrCreateTodaysDare(
    SupabaseClient client,
    String coupleId,
    String apiKey, {
    int totalBattles = 0,
    int streakDays = 0,
    String? packId,
    String? packPersonaPromptOverride,
    String? packThemeContext,
  }) async {
    try {
      // Expire stale dares first
      await _expireStale(client, coupleId);

      final today = _todayString();

      // Check if dare already exists for today
      final existing = await client
          .from('daily_dares')
          .select()
          .eq('couple_id', coupleId)
          .eq('dare_date', today)
          .maybeSingle();

      if (existing != null) return DailyDare.fromJson(existing);

      // Determine today's persona via deterministic rotation
      final dayOfYear = DateTime.now()
          .difference(DateTime(DateTime.now().year, 1, 1))
          .inDays;
      final persona = AppConstants.darePersonaRotation[
          dayOfYear % AppConstants.darePersonaRotation.length];

      // Fetch recent dare texts to avoid repeats
      final recentRows = await client
          .from('daily_dares')
          .select('dare_text')
          .eq('couple_id', coupleId)
          .order('dare_date', ascending: false)
          .limit(3);
      final recentTexts =
          (recentRows as List).map((r) => r['dare_text'] as String).toList();

      // Fetch judge memories for personalization
      final memories =
          await JudgeMemoryService.getMemories(client, coupleId, persona);

      // Generate dare via AI
      final judge = AiJudgeService(apiKey: apiKey);
      final result = await judge.generateDare(
        persona: persona,
        recentDareTexts: recentTexts,
        judgeMemories: memories,
        totalBattles: totalBattles,
        streakDays: streakDays,
        personaPromptOverride: packPersonaPromptOverride,
        packThemeContext: packThemeContext,
      );

      // Insert with upsert for race-condition safety
      final row = await client
          .from('daily_dares')
          .upsert(
            {
              'couple_id': coupleId,
              'dare_date': today,
              'judge_persona': persona,
              'dare_text': result.dareText,
              'dare_category': result.category,
              'status': 'pending',
              if (packId != null) 'pack_id': packId,
            },
            onConflict: 'couple_id,dare_date',
          )
          .select()
          .single();

      return DailyDare.fromJson(row);
    } catch (e) {
      debugPrint('DailyDareService.getOrCreateTodaysDare: $e');
      return null;
    }
  }

  /// Submit the current user's response to a dare.
  /// Determines user_a vs user_b based on [userId] vs [userAId].
  /// Returns the updated dare.
  static Future<DailyDare?> submitResponse(
    SupabaseClient client, {
    required String dareId,
    required String coupleId,
    required String userId,
    required String userAId,
    required String plainContent,
    String responseType = 'text',
  }) async {
    try {
      final encrypted =
          await EncryptionService.encrypt(plainContent, coupleId: coupleId);

      final isUserA = userId == userAId;
      final now = DateTime.now().toUtc().toIso8601String();

      // Fetch current state to determine new status
      final current = await client
          .from('daily_dares')
          .select()
          .eq('id', dareId)
          .single();
      final dare = DailyDare.fromJson(current);

      // Check if partner already submitted
      final partnerDone = isUserA
          ? dare.userBSubmittedAt != null
          : dare.userASubmittedAt != null;
      final newStatus = partnerDone ? 'complete' : 'partial';

      final updates = <String, dynamic>{
        'status': newStatus,
      };
      if (isUserA) {
        updates['user_a_response_encrypted'] = encrypted;
        updates['user_a_response_type'] = responseType;
        updates['user_a_submitted_at'] = now;
      } else {
        updates['user_b_response_encrypted'] = encrypted;
        updates['user_b_response_type'] = responseType;
        updates['user_b_submitted_at'] = now;
      }

      final row = await client
          .from('daily_dares')
          .update(updates)
          .eq('id', dareId)
          .select()
          .single();

      return DailyDare.fromJson(row);
    } catch (e) {
      debugPrint('DailyDareService.submitResponse: $e');
      return null;
    }
  }

  /// Grades a completed dare via AI. Both responses are decrypted, sent to the
  /// judge, and the grade is stored. Returns the updated dare.
  static Future<DailyDare?> gradeDare(
    SupabaseClient client,
    String apiKey,
    DailyDare dare,
    String coupleId,
  ) async {
    try {
      // Decrypt both responses
      final responseA = dare.userAResponseEncrypted != null
          ? await EncryptionService.decrypt(
              dare.userAResponseEncrypted!,
              coupleId: coupleId,
            )
          : '';
      final responseB = dare.userBResponseEncrypted != null
          ? await EncryptionService.decrypt(
              dare.userBResponseEncrypted!,
              coupleId: coupleId,
            )
          : '';

      final judge = AiJudgeService(apiKey: apiKey);
      final grade = await judge.gradeDare(
        persona: dare.judgePersona,
        dareText: dare.dareText,
        responseA: responseA,
        responseB: responseB,
      );

      final now = DateTime.now().toUtc().toIso8601String();
      final row = await client
          .from('daily_dares')
          .update({
            'grade_commentary': grade.commentary,
            'grade_score': grade.score,
            'grade_emoji': grade.emoji,
            'grade_roast': grade.roast,
            'graded_at': now,
            'status': 'graded',
          })
          .eq('id', dare.id)
          .select()
          .single();

      return DailyDare.fromJson(row);
    } catch (e) {
      debugPrint('DailyDareService.gradeDare: $e');
      return null;
    }
  }

  /// Marks any past-due dares as expired.
  static Future<void> _expireStale(
    SupabaseClient client,
    String coupleId,
  ) async {
    try {
      await client
          .from('daily_dares')
          .update({'status': 'expired'})
          .eq('couple_id', coupleId)
          .inFilter('status', ['pending', 'partial'])
          .lt('expires_at', DateTime.now().toUtc().toIso8601String());
    } catch (e) {
      debugPrint('DailyDareService._expireStale: $e');
    }
  }

  /// Fetches last [limit] dares for a couple (for dare history).
  static Future<List<DailyDare>> getRecentDares(
    SupabaseClient client,
    String coupleId, {
    int limit = 7,
  }) async {
    try {
      final rows = await client
          .from('daily_dares')
          .select()
          .eq('couple_id', coupleId)
          .order('dare_date', ascending: false)
          .limit(limit);
      return (rows as List).map((r) => DailyDare.fromJson(r)).toList();
    } catch (e) {
      debugPrint('DailyDareService.getRecentDares: $e');
      return [];
    }
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
