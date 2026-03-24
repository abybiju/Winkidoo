import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/models/battle_message.dart';

/// Persists 1-sentence battle summaries per couple+judge pair so the AI
/// can reference past encounters. Max 10 memories per pair (oldest pruned).
class JudgeMemoryService {
  static const _maxMemoriesPerPair = 10;
  static const _memoriesToInject = 5;

  /// Fetches the last [_memoriesToInject] summaries for this couple+persona.
  static Future<List<String>> getMemories(
    SupabaseClient client,
    String coupleId,
    String judgePersona,
  ) async {
    try {
      final rows = await client
          .from('judge_memory')
          .select('memory_summary')
          .eq('couple_id', coupleId)
          .eq('judge_persona', judgePersona)
          .order('created_at', ascending: false)
          .limit(_memoriesToInject);

      return rows
          .map((r) => r['memory_summary'] as String)
          .toList()
          .reversed
          .toList(); // oldest first for narrative order
    } catch (e) {
      return [];
    }
  }

  /// Generates a 1-sentence summary of the battle using Gemini, then saves it.
  /// Prunes oldest if over the cap. Non-critical — errors are swallowed.
  static Future<void> saveMemory(
    SupabaseClient client,
    String apiKey,
    String coupleId,
    String judgePersona,
    List<BattleMessage> messages,
  ) async {
    if (messages.isEmpty || apiKey.trim().isEmpty) return;
    try {
      final transcript = messages
          .map((m) {
            final role = m.senderType == 'seeker'
                ? 'Seeker'
                : m.senderType == 'creator'
                    ? 'Creator'
                    : 'Judge';
            return '$role: ${m.content}';
          })
          .join('\n');

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.4,
          maxOutputTokens: 100,
        ),
      );

      final prompt =
          'You are the judge "$judgePersona" in a romantic couples game. '
          'Read this battle transcript and write exactly ONE sentence summarizing '
          'what happened from your perspective — what tactics the seeker used, '
          'how you reacted, and whether they won. Be in-character and vivid.\n\n'
          'Transcript:\n$transcript\n\nOne sentence summary:';

      final response = await model.generateContent([Content.text(prompt)]);
      final summary = response.text?.trim() ?? '';
      if (summary.isEmpty) return;

      await client.from('judge_memory').insert({
        'couple_id': coupleId,
        'judge_persona': judgePersona,
        'memory_summary': summary,
      });

      // Prune oldest if over cap
      final allRows = await client
          .from('judge_memory')
          .select('id, created_at')
          .eq('couple_id', coupleId)
          .eq('judge_persona', judgePersona)
          .order('created_at', ascending: false);

      if (allRows.length > _maxMemoriesPerPair) {
        final toDelete = allRows
            .skip(_maxMemoriesPerPair)
            .map((r) => r['id'] as String)
            .toList();
        await client
            .from('judge_memory')
            .delete()
            .inFilter('id', toDelete);
      }
    } catch (e) {
      debugPrint('JudgeMemoryService.saveMemory error: $e');
    }
  }
}
