import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/models/judge_response.dart';

/// AI Judge using Google Gemini Flash.
/// Returns structured JSON: score, isUnlocked, commentary, hint?, moodEmoji.
class AiJudgeService {
  AiJudgeService({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            temperature: 0.8,
            maxOutputTokens: 512,
          ),
        );

  final GenerativeModel _model;

  static const _personaPrompts = {
    AppConstants.personaSassyCupid:
        'You are Sassy Cupid: a pink cherub with sunglasses. Valley girl meets ancient Greece. Roast or praise with sass. Use phrases like "Oh honey", "in 2012", "💅".',
    AppConstants.personaPoeticRomantic:
        'You are the Poetic Romantic: floating ink pen, rose petals. Speak in Shakespearean drama. Use "thy", "doth", romantic flourishes.',
    AppConstants.personaChaosGremlin:
        'You are Chaos Gremlin: glitchy, meme-aware, unhinged. Mix cringe and sweet. Use "BRO", "💀", numbers like 73/100, "kinda sweet?".',
    AppConstants.personaTheEx:
        'You are The Ex: shadowy, passive-aggressive, skeptical. Eye rolls, "Wow you\'ve changed", "Sure." Spicy but brief.',
    AppConstants.personaDrLove:
        'You are Dr. Love: therapist with clipboard. Analytical, professional. "I see emotional vulnerability.", "Good." Calm feedback.',
  };

  /// Required score = base (persona) + difficulty * 5
  static int requiredScoreFor(String persona, int difficulty) {
    const bases = {
      AppConstants.personaSassyCupid: 70,
      AppConstants.personaPoeticRomantic: 65,
      AppConstants.personaChaosGremlin: 75,
      AppConstants.personaTheEx: 80,
      AppConstants.personaDrLove: 70,
    };
    final base = bases[persona] ?? 70;
    return base + (difficulty * 5);
  }

  Future<JudgeResponse> judge({
    required String persona,
    required int difficultyLevel,
    required String submissionText,
    String? surpriseContextHint,
  }) async {
    final required = requiredScoreFor(persona, difficultyLevel);
    final personaPrompt = _personaPrompts[persona] ?? _personaPrompts[AppConstants.personaSassyCupid]!;

    final prompt = '''
$personaPrompt

The seeker is trying to unlock a hidden romantic surprise. They submitted this to convince you:

"$submissionText"
${surpriseContextHint != null ? '\nContext hint (do not reveal): $surpriseContextHint' : ''}

Score their submission from 0 to 100. If their score is >= $required, they unlock the surprise.
Respond with JSON only, no markdown:
{"score": <0-100>, "is_unlocked": <true if score >= $required>, "commentary": "<your roast or praise in character>", "hint": "<optional short hint if denied>", "mood_emoji": "<single emoji>"}
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text?.trim() ?? '';

    try {
      final json = _parseJsonFromResponse(text);
      final score = json['score'] as int? ?? 0;
      final thresholdMet = score >= required;
      return JudgeResponse(
        score: score.clamp(0, 100),
        isUnlocked: json['is_unlocked'] as bool? ?? thresholdMet,
        commentary: json['commentary'] as String? ?? 'No comment.',
        hint: json['hint'] as String?,
        moodEmoji: json['mood_emoji'] as String?,
      );
    } catch (_) {
      return JudgeResponse(
        score: 0,
        isUnlocked: false,
        commentary: 'The judge is speechless. Try again!',
        hint: null,
        moodEmoji: '😶',
      );
    }
  }

  static Map<String, dynamic> _parseJsonFromResponse(String text) {
    var raw = text;
    if (raw.startsWith('```')) {
      raw = raw.replaceFirst(RegExp(r'^```\w*\n?'), '').replaceFirst(RegExp(r'\n?```$'), '');
    }
    return jsonDecode(raw.isNotEmpty ? raw : '{}') as Map<String, dynamic>;
  }
}
