import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Searches the web for personality info via the `tavily-proxy` Edge Function.
/// The Tavily API key lives server-side (a Supabase secret), so it never ships
/// in the client. Free tier: 1,000 searches/month.
class TavilySearchService {
  /// Searches the web for information about a personality.
  /// Returns a concatenated string of search results (titles + content)
  /// ready to be injected into an AI prompt.
  ///
  /// Returns empty string if search fails (graceful fallback to AI-only).
  static Future<String> searchPersonality(String personalityName) async {
    debugPrint('TavilySearchService: Starting search for "$personalityName"');

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'tavily-proxy',
        method: HttpMethod.post,
        body: {
          'query':
              '$personalityName famous quotes speaking style personality mannerisms catchphrases',
          'max_results': 5,
          'include_answer': true,
          'search_depth': 'basic',
        },
      );

      debugPrint('TavilySearchService: proxy status ${response.status}');
      if (response.status != 200) {
        debugPrint('TavilySearchService: proxy HTTP ${response.status}');
        return '';
      }

      final json = response.data as Map<String, dynamic>;

      final buffer = StringBuffer();

      // Include the AI-generated answer if available
      final answer = json['answer'] as String?;
      if (answer != null && answer.isNotEmpty) {
        buffer.writeln('Summary: $answer');
        buffer.writeln();
      }

      // Include individual search results
      final results = json['results'] as List? ?? [];
      for (final result in results) {
        final title = result['title'] as String? ?? '';
        final content = result['content'] as String? ?? '';
        if (content.isNotEmpty) {
          buffer.writeln('Source: $title');
          buffer.writeln(content);
          buffer.writeln();
        }
      }

      final searchContext = buffer.toString().trim();
      if (searchContext.isEmpty) {
        debugPrint('TavilySearchService: No results for "$personalityName"');
      }
      return searchContext;
    } catch (e) {
      debugPrint('TavilySearchService.searchPersonality error: $e');
      return '';
    }
  }
}
