import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/models/custom_judge.dart';
import 'package:winkidoo/services/ai_judge_service.dart';
import 'package:winkidoo/services/tavily_search_service.dart';

/// Service for custom AI judge creation and marketplace.
class CustomJudgeService {
  /// Creates a custom judge with web search + AI persona generation.
  /// Flow: insert row as 'generating' → search web → generate persona → update to 'ready'.
  /// [onStatusUpdate] is called at each stage for UI progress.
  static Future<CustomJudge?> createJudge(
    SupabaseClient client,
    String geminiApiKey, {
    required String coupleId,
    required String personalityName,
    required String mood,
    String? avatarStoragePath,
    String tavilyApiKey = '',
    void Function(String status)? onStatusUpdate,
  }) async {
    try {
      // Step 1: Insert row with 'generating' status
      onStatusUpdate?.call('searching');
      final insertRow = await client
          .from('custom_judges')
          .insert({
            'couple_id': coupleId,
            'personality_name': personalityName,
            'personality_query': personalityName,
            'mood': mood,
            'generated_persona_prompt': 'Generating...',
            'avatar_storage_path': avatarStoragePath,
            'avatar_emoji': '🎭',
            'difficulty_level': 2,
            'chaos_level': 2,
            'status': 'generating',
          })
          .select()
          .single();
      final judgeId = insertRow['id'] as String;

      // Step 2: Search the web for personality info via Tavily
      String webContext = '';
      debugPrint('CustomJudgeService: tavilyApiKey empty=${tavilyApiKey.isEmpty}');
      if (tavilyApiKey.isNotEmpty) {
        webContext = await TavilySearchService.searchPersonality(
          tavilyApiKey,
          personalityName,
        );
        debugPrint('CustomJudgeService: Tavily returned ${webContext.length} chars');
      } else {
        debugPrint('CustomJudgeService: No Tavily key, skipping web search');
      }

      // Step 3: Generate persona via AI with web context
      onStatusUpdate?.call('generating');
      final judge = AiJudgeService(apiKey: geminiApiKey);
      final result = await judge.generateCustomPersona(
        personalityName: personalityName,
        mood: mood,
        webSearchContext: webContext,
      );

      if (result.error != null) {
        // Mark as failed
        await client
            .from('custom_judges')
            .update({'status': 'failed'})
            .eq('id', judgeId);
        debugPrint('CustomJudgeService.createJudge: ${result.error}');
        return null;
      }

      // Step 4: Update row with generated data + 'ready' status
      onStatusUpdate?.call('ready');
      final row = await client
          .from('custom_judges')
          .update({
            'generated_persona_prompt': result.personaPrompt,
            'generated_how_to_impress': result.howToImpress,
            'preview_quotes': result.previewQuotes,
            'avatar_emoji': result.avatarEmoji,
            'difficulty_level': result.suggestedDifficulty,
            'chaos_level': result.suggestedChaos,
            'notification_text': result.notificationText,
            'status': 'ready',
          })
          .eq('id', judgeId)
          .select()
          .single();

      return CustomJudge.fromJson(row);
    } catch (e) {
      debugPrint('CustomJudgeService.createJudge: $e');
      return null;
    }
  }

  /// Gets the couple's own custom judges.
  static Future<List<CustomJudge>> getMyJudges(
    SupabaseClient client,
    String coupleId,
  ) async {
    try {
      final rows = await client
          .from('custom_judges')
          .select()
          .eq('couple_id', coupleId)
          .order('created_at', ascending: false);
      return (rows as List).map((r) => CustomJudge.fromJson(r)).toList();
    } catch (e) {
      debugPrint('CustomJudgeService.getMyJudges: $e');
      return [];
    }
  }

  /// Publishes a custom judge to the marketplace.
  static Future<void> publishJudge(
    SupabaseClient client,
    String judgeId,
  ) async {
    try {
      await client
          .from('custom_judges')
          .update({'is_published': true})
          .eq('id', judgeId);
    } catch (e) {
      debugPrint('CustomJudgeService.publishJudge: $e');
    }
  }

  /// Unpublishes a custom judge from the marketplace.
  static Future<void> unpublishJudge(
    SupabaseClient client,
    String judgeId,
  ) async {
    try {
      await client
          .from('custom_judges')
          .update({'is_published': false})
          .eq('id', judgeId);
    } catch (e) {
      debugPrint('CustomJudgeService.unpublishJudge: $e');
    }
  }

  /// Gets published marketplace judges, ordered by use count.
  static Future<List<CustomJudge>> getMarketplaceJudges(
    SupabaseClient client, {
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      var query = client
          .from('custom_judges')
          .select()
          .eq('is_published', true)
          .eq('is_flagged', false);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('personality_name', '%$searchQuery%');
      }

      final rows = await query
          .order('use_count', ascending: false)
          .limit(limit);
      return (rows as List).map((r) => CustomJudge.fromJson(r)).toList();
    } catch (e) {
      debugPrint('CustomJudgeService.getMarketplaceJudges: $e');
      return [];
    }
  }

  /// Gets top trending judges.
  static Future<List<CustomJudge>> getTrendingJudges(
    SupabaseClient client, {
    int limit = 10,
  }) async {
    try {
      final rows = await client
          .from('custom_judges')
          .select()
          .eq('is_published', true)
          .eq('is_flagged', false)
          .gt('use_count', 0)
          .order('use_count', ascending: false)
          .limit(limit);
      return (rows as List).map((r) => CustomJudge.fromJson(r)).toList();
    } catch (e) {
      debugPrint('CustomJudgeService.getTrendingJudges: $e');
      return [];
    }
  }

  /// Adds a marketplace judge to the couple's collection and increments use count.
  static Future<void> useJudge(
    SupabaseClient client, {
    required String customJudgeId,
    required String coupleId,
  }) async {
    try {
      // Add to uses
      await client.from('custom_judge_uses').upsert({
        'custom_judge_id': customJudgeId,
        'couple_id': coupleId,
      }, onConflict: 'custom_judge_id,couple_id');

      // Increment use count
      final row = await client
          .from('custom_judges')
          .select('use_count')
          .eq('id', customJudgeId)
          .single();
      final current = (row['use_count'] as int?) ?? 0;
      await client
          .from('custom_judges')
          .update({'use_count': current + 1})
          .eq('id', customJudgeId);
    } catch (e) {
      debugPrint('CustomJudgeService.useJudge: $e');
    }
  }

  /// Gets judges the couple has added from the marketplace.
  static Future<List<CustomJudge>> getAdoptedJudges(
    SupabaseClient client,
    String coupleId,
  ) async {
    try {
      final useRows = await client
          .from('custom_judge_uses')
          .select('custom_judge_id')
          .eq('couple_id', coupleId);
      final ids = (useRows as List)
          .map((r) => r['custom_judge_id'] as String)
          .toList();
      if (ids.isEmpty) return [];

      final rows = await client
          .from('custom_judges')
          .select()
          .inFilter('id', ids)
          .eq('is_flagged', false);
      return (rows as List).map((r) => CustomJudge.fromJson(r)).toList();
    } catch (e) {
      debugPrint('CustomJudgeService.getAdoptedJudges: $e');
      return [];
    }
  }

  /// Deletes a custom judge (only the creator's couple).
  static Future<void> deleteJudge(
    SupabaseClient client,
    String judgeId,
  ) async {
    try {
      await client.from('custom_judges').delete().eq('id', judgeId);
    } catch (e) {
      debugPrint('CustomJudgeService.deleteJudge: $e');
    }
  }
}
