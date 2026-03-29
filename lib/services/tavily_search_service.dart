import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Searches the web for personality info using Tavily's free API.
/// Free tier: 1,000 searches/month.
class TavilySearchService {
  static const _baseUrl = 'https://api.tavily.com/search';

  /// Searches the web for information about a personality.
  /// Returns a concatenated string of search results (titles + content)
  /// ready to be injected into an AI prompt.
  ///
  /// Returns empty string if search fails (graceful fallback to AI-only).
  static Future<String> searchPersonality(
    String apiKey,
    String personalityName,
  ) async {
    if (apiKey.trim().isEmpty) {
      debugPrint('TavilySearchService: No API key, skipping web search');
      return '';
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_key': apiKey,
          'query':
              '$personalityName famous quotes speaking style personality mannerisms catchphrases',
          'max_results': 5,
          'include_answer': true,
          'search_depth': 'basic',
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
            'TavilySearchService: HTTP ${response.statusCode} — ${response.body}');
        return '';
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

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
