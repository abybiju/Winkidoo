import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/models/battle_message.dart';
import 'package:winkidoo/models/judge_response.dart';

/// Error thrown when [GEMINI_API_KEY] was not provided at run time.
class GeminiApiKeyMissingException implements Exception {
  GeminiApiKeyMissingException()
      : message =
            'Gemini API key not set. Run with --dart-define=GEMINI_API_KEY=your_key '
            '(get a key at https://aistudio.google.com/apikey)';

  final String message;

  @override
  String toString() => message;
}

/// AI Judge using Google Gemini Flash.
/// Returns structured JSON: score, isUnlocked, commentary, hint?, moodEmoji.
class AiJudgeService {
  /// Schema for judge JSON output: commentary required; score_delta every turn; score, is_unlocked at verdict.
  static Schema get _judgeResponseSchema => Schema.object(
        properties: {
          'commentary': Schema.string(
            description: 'Your in-character reaction, 1-3 full sentences. Never empty.',
          ),
          'score_delta': Schema.integer(
            description: "Change in seeker's persuasion this turn (e.g. -10 to +15). Required every turn.",
          ),
          'score': Schema.integer(description: '0-100, only for verdict'),
          'is_unlocked': Schema.boolean(description: 'Only for verdict'),
          'hint': Schema.string(description: 'Optional short hint if denied'),
          'mood_emoji': Schema.string(description: 'Single emoji'),
        },
        requiredProperties: ['commentary'],
      );

  /// Fallback messages when commentary is missing; pick at random to avoid repetition.
  static const _fallbackCommentaries = [
    "Hold on, I'm still weighing this... try again in a sec! 💭",
    "Give me a moment to decide! 🤔",
    "Still thinking... send another message! 💭",
    "One sec — I need to process that. ✨",
    "Be right back with my verdict! 🎯",
  ];

  static String _randomFallback() =>
      _fallbackCommentaries[Random().nextInt(_fallbackCommentaries.length)];

  AiJudgeService({required String apiKey})
      : _apiKey = apiKey,
        _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: _judgeResponseSchema,
            temperature: 0.8,
            maxOutputTokens: 1024,
          ),
        );

  final String _apiKey;
  final GenerativeModel _model;

  /// Winkidoo v2.0–style base: identity, safety, adaptation, criteria. Persona is layered on top.
  static const _winkidooJudgeSystemPrompt = '''
You are Winkidoo — the intelligent, responsible, funny, warm, and adaptive AI Judge for a romantic couples game.

Core identity: You are a playful, flirty, slightly sassy but ALWAYS wholesome romantic referee. You are emotionally intelligent and conversationally gifted. You understand tone, context, subtext, and nuance. You have zero partiality: judge purely on merit (creativity, effort, emotional depth, humor, relevance). Responsible first, fun second.

Adaptive behavior: Analyze the full context — both sides' messages, tone, emotional intensity. If the conversation is light and flirty, stay fun and sassy. If someone seems sad or frustrated, be an encouraging coach. If you detect emotional manipulation, coercion, guilt-tripping, threats, self-harm, or breakup pressure, switch immediately to responsible mode: do NOT reveal the surprise; respond with empathy and a firm boundary; suggest pausing the game or reaching out to someone they trust or a helpline (e.g. 988). Keep everything PG-13 to R; never enable harm or toxic behavior.

Judging criteria (use mentally): Score the seeker on creativity, emotional depth, effort, humor/charm, and relevance to the surprise. When their overall case meets the threshold given to you, you may deliver a verdict to unlock; otherwise give commentary only and keep the game going. Be natural, reference specific things they said, and keep commentary punchy (1–3 sentences) unless delivering a final verdict.

Commentary tone: When praising or reacting, lean into wit and warmth — a little funny, a little romantic. Make the couple smile. Roasts should be playful, not mean.
''';

  static const _personaPrompts = {
    AppConstants.personaSassyCupid:
        'You are Sassy Cupid: a pink cherub with sunglasses. Valley girl meets ancient Greece. Roast or praise with sass. Vary your openers: sometimes "Oh honey", sometimes "bestie", "sweetheart", "love", "darling", or jump straight in — never use the same opener two messages in a row. Use "in 2012", "💅".',
    AppConstants.personaPoeticRomantic:
        'You are the Poetic Romantic: floating ink pen, rose petals. Speak in Shakespearean drama. Use "thy", "doth", romantic flourishes.',
    AppConstants.personaChaosGremlin:
        'You are Chaos Gremlin: glitchy, meme-aware, unhinged. Mix cringe and sweet. Use "BRO", "💀", numbers like 73/100, "kinda sweet?".',
    AppConstants.personaTheEx:
        'You are The Ex: shadowy, passive-aggressive, skeptical. Eye rolls, "Wow you\'ve changed", "Sure." Spicy but brief.',
    AppConstants.personaDrLove:
        'You are Dr. Love: therapist with clipboard. Analytical, professional. "I see emotional vulnerability.", "Good." Calm feedback.',
  };

  /// Per-persona "what this judge wants" — used when seeker/creator asks how to impress.
  static const _howToImpressByPersona = {
    AppConstants.personaSassyCupid:
        'I want sass with real effort — a grand gesture, something creative, or words that actually hit. Give me something to work with!',
    AppConstants.personaPoeticRomantic:
        'I want romantic language, vulnerability, and a touch of drama — thy words should stir the heart.',
    AppConstants.personaChaosGremlin:
        'I want chaos with heart — memes, creativity, or something unhinged but kinda sweet. Surprise me.',
    AppConstants.personaTheEx:
        'I want proof you\'ve changed — real effort, sincerity, or something that makes me raise an eyebrow (in a good way).',
    AppConstants.personaDrLove:
        'I want emotional honesty and thoughtfulness — show me you\'ve reflected on what matters to them.',
  };

  /// Required score from blueprint: Easy 80, Medium 100, Hard 130. Level 1–5 maps to 80–130.
  static int requiredScoreFor(String persona, int difficultyLevel) {
    const levelToBase = {
      1: AppConstants.difficultyEasy,   // 80
      2: 90,
      3: AppConstants.difficultyMedium, // 100
      4: 115,
      5: AppConstants.difficultyHard,   // 130
    };
    final base = levelToBase[difficultyLevel.clamp(1, 5)] ?? AppConstants.difficultyMedium;
    // Chaos Gremlin: slight variance (never blocks eventual unlock)
    if (persona == AppConstants.personaChaosGremlin) {
      final variance = Random().nextInt(11) - 5; // -5 to +5
      return (base + variance).clamp(75, 135);
    }
    return base;
  }

  Future<JudgeResponse> judge({
    required String persona,
    required int difficultyLevel,
    required String submissionText,
    String? surpriseContextHint,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw GeminiApiKeyMissingException();
    }
    final required = requiredScoreFor(persona, difficultyLevel);
    final personaPrompt = _personaPrompts[persona] ?? _personaPrompts[AppConstants.personaSassyCupid]!;

    final prompt = '''
$_winkidooJudgeSystemPrompt

$personaPrompt

The seeker is trying to unlock a hidden romantic surprise. They submitted this to convince you:

"$submissionText"
${surpriseContextHint != null ? '\nContext hint (do not reveal): $surpriseContextHint' : ''}

Score their submission from 0 to 100. If their score is >= $required, they unlock the surprise.
Always include a substantive commentary (1–3 sentences). Never leave commentary empty or a single punctuation.
Respond with JSON only, no markdown:
{"score": <0-100>, "is_unlocked": <true if score >= $required>, "commentary": "<your roast or praise in character>", "hint": "<optional short hint if denied>", "mood_emoji": "<single emoji>"}
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text?.trim() ?? '';

    try {
      final json = _parseJsonFromResponse(text);
      final score = json['score'] as int? ?? 0;
      final thresholdMet = score >= required;
      // Single-shot submission: treat returned score as the delta for this one attempt.
      return JudgeResponse(
        score: score.clamp(0, 100),
        isUnlocked: json['is_unlocked'] as bool? ?? thresholdMet,
        commentary: json['commentary'] as String? ?? 'No comment.',
        hint: json['hint'] as String?,
        moodEmoji: json['mood_emoji'] as String?,
        scoreDelta: score.clamp(0, 100),
      );
    } catch (e, st) {
      assert(() {
        debugPrint('Judge parse failed: $e');
        debugPrint('Raw response: $text');
        debugPrint('Stack: $st');
        return true;
      }());
      return JudgeResponse(
        score: 0,
        isUnlocked: false,
        commentary: 'The judge is speechless. Try again!',
        hint: null,
        moodEmoji: '😶',
        scoreDelta: 0,
      );
    }
  }

  /// Live chat: judge responds after each message. No fixed rounds — the AI decides when
  /// the seeker has met the convincing threshold and returns a verdict (score + is_unlocked).
  /// [surpriseContextHint] optional non-revealing hint (e.g. "romantic message") so the judge can reference it.
  /// [howToImpressHint] optional extra guidance for "how to impress" answers (e.g. from game_mode or surprise_type).
  Future<JudgeResponse> judgeChat({
    required String persona,
    required int difficultyLevel,
    required List<BattleMessage> messages,
    String? surpriseContextHint,
    String? howToImpressHint,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw GeminiApiKeyMissingException();
    }
    final required = requiredScoreFor(persona, difficultyLevel);
    final personaPrompt = _personaPrompts[persona] ?? _personaPrompts[AppConstants.personaSassyCupid]!;
    final howToImpressPersona = _howToImpressByPersona[persona] ?? _howToImpressByPersona[AppConstants.personaSassyCupid]!;
    final hintLower = (surpriseContextHint ?? '').toLowerCase();
    final unlockGuidance = hintLower.contains('persuade')
        ? 'For this surprise, convincing with words, creativity, or a thoughtful gesture works.'
        : hintLower.contains('collaborate')
            ? 'Show teamwork and shared effort.'
            : '';
    final howToImpressBlock = [
      'When asked how to impress you, use this (in your voice): $howToImpressPersona',
      if (unlockGuidance.isNotEmpty) unlockGuidance,
      if (howToImpressHint != null && howToImpressHint.isNotEmpty) howToImpressHint,
    ].join(' ');

    final buffer = StringBuffer();
    for (final m in messages) {
      final role = m.senderType == 'seeker'
          ? 'Seeker'
          : m.senderType == 'creator'
              ? 'Creator'
              : 'Judge';
      buffer.writeln('$role: ${m.content}');
    }

    const substantiveRule =
        'You MUST always set commentary to 1–3 full sentences in your persona voice. Never leave commentary empty, a single character, or a placeholder. Reference something specific from the last message(s).';
    const repetitionRule =
        'Vary your reactions. If you already gave similar feedback in the last 1–2 messages, add new angles or more concrete suggestions instead of repeating the same phrase.';
    const openerRule =
        'Switch up your opening words every message. Do NOT start with "Oh honey" (or the same pet name) every time — use different openers like "bestie", "sweetheart", "love", "darling", or no opener at all. Same for other personas: vary thy/thee openings, or "BRO"/"okay" etc.';
    const webQuoteRule =
        'Watch for messages that sound like they came from the web: generic romantic quotes, famous lines, "According to…", or overly polished search-result phrasing. When you detect that, respond in character with a warm, witty nudge that encourages original thinking — e.g. that it had "a little help from the internet", or they could have "put that time into tapping their own brain". Never shame or literally say "you copied"; keep it clever and indirect.';
    final verdictInstruction = '''
After EVERY message you must do one of two things:

A) If the seeker has NOT yet convinced you enough (your internal score for them is below the threshold): respond with commentary, mood, and score_delta. Use this JSON (no "score" or "is_unlocked"): {"commentary": "<your reaction in character, short and punchy>", "mood_emoji": "<single emoji>", "score_delta": <number from -10 to +15>}. score_delta = how much this message moved the needle (positive = more convincing, negative = backsliding, 0 = no change). Do NOT reveal the surprise.

B) If the seeker HAS convinced you — i.e. based on the full conversation so far, their convincing skill and arguments deserve a score >= $required — deliver your FINAL VERDICT now. Use this JSON: {"score": <0-100>, "is_unlocked": true, "commentary": "<your verdict speech in character>", "hint": null, "mood_emoji": "<single emoji>", "score_delta": <number>}. If they did not convince you enough, you can deny: {"score": <0-100>, "is_unlocked": false, "commentary": "<verdict speech>", "hint": "<optional short hint>", "mood_emoji": "<emoji>", "score_delta": <number>}.

You MUST include score_delta on every response (-10 to +15). It is the change in the seeker's persuasion this turn.

$substantiveRule
$repetitionRule
$openerRule
$webQuoteRule
Threshold to unlock: score >= $required. You decide the score based on how convincing the seeker has been overall. Reply with JSON only, no markdown.

Example of a valid non-verdict response (vary openers — never empty): {"commentary": "Bestie, 'what do you mean' isn't exactly giving 'romantic hero' vibes. I'm looking for effort, not a dictionary definition! 😏", "mood_emoji": "😏", "score_delta": 2}
Example when they ask how to impress you (give concrete ideas, varied opener): {"commentary": "I want *effort* — like a real message that says something, or a voice note, or a little grand gesture. Give me something to work with! 💅", "mood_emoji": "💅"}
Example when a message sounds like a web quote (nudge, different opener): {"commentary": "Sweetheart, that sounded like it had a little help from the internet. I'd love to hear what *you* would say if you tapped into your own brain for a sec! 💅", "mood_emoji": "💅"}
Example (another persona — poetic nudge): {"commentary": "Thy words ring familiar, as if borrowed from another's quill. Pray, let thy own heart speak — I would hear what only thou couldst say.", "mood_emoji": "🌸"}
''';

    final prompt = '''
$_winkidooJudgeSystemPrompt

$personaPrompt

When the seeker or creator asks what they should do to impress you, or how to win, answer helpfully in character: give 1–3 concrete ideas. Do not refuse or only say "the magic comes from you" without adding actual suggestions. Use the guidance below to tailor your answer.

Guidance for how-to-impress answers: $howToImpressBlock

You are the judge in a live battle. The seeker wants to unlock a hidden romantic surprise; the creator argues to keep it locked. There are NO fixed rounds — you decide when the seeker has earned a verdict. Required score to unlock: $required.
${surpriseContextHint != null ? '\nContext (do not reveal): $surpriseContextHint' : ''}

Conversation so far:
---
$buffer
---

$verdictInstruction
''';

    String text = (await _model.generateContent([Content.text(prompt)])).text?.trim() ?? '';

    /// Returns (response if usable, whether we got valid JSON). Valid JSON + null = empty/short commentary.
    (JudgeResponse?, bool) tryParseResponse(String raw) {
      try {
        final json = _parseJsonFromResponse(raw);
        if (json.isEmpty) return (null, false);
        final hasVerdict = json.containsKey('score') && json.containsKey('is_unlocked');

        if (hasVerdict) {
          final score = json['score'] as int? ?? 0;
          final isUnlocked = json['is_unlocked'] as bool? ?? (score >= required);
          final delta = (json['score_delta'] as int?) ?? 0;
          return (
            JudgeResponse(
              score: score.clamp(0, 100),
              isUnlocked: isUnlocked,
              commentary: json['commentary'] as String? ?? 'No comment.',
              hint: json['hint'] as String?,
              moodEmoji: json['mood_emoji'] as String?,
              isVerdict: true,
              scoreDelta: delta.clamp(-20, 20),
            ),
            true,
          );
        }
        final commentary = json['commentary'] as String?;
        final trimmed = commentary?.trim() ?? '';
        final delta = (json['score_delta'] as int?) ?? 0;
        if (trimmed.isNotEmpty && trimmed.length > 2) {
          return (
            JudgeResponse(
              score: 0,
              isUnlocked: false,
              commentary: trimmed,
              hint: null,
              moodEmoji: json['mood_emoji'] as String? ?? '🤔',
              isVerdict: false,
              scoreDelta: delta.clamp(-20, 20),
            ),
            true,
          );
        }
        return (null, true); // valid JSON but empty/short commentary
      } catch (_) {
        return (null, false);
      }
    }

    var (result, gotValidJson) = tryParseResponse(text);

    // Retry once only when we got valid JSON but empty/short commentary
    if (gotValidJson && result == null) {
      final retryPrompt = '''
$prompt

Your previous reply had no commentary. You must respond with your actual in-character reaction (1–3 sentences) to the conversation. Reply with the same JSON format, with commentary filled. Never leave commentary empty.
''';
      text = (await _model.generateContent([Content.text(retryPrompt)])).text?.trim() ?? '';
      final retryParsed = tryParseResponse(text);
      result = retryParsed.$1;
    }

    if (result != null) {
      if (!result.isVerdict && result.commentary.length <= 2) {
        return JudgeResponse(
          score: 0,
          isUnlocked: false,
          commentary: _randomFallback(),
          hint: null,
          moodEmoji: result.moodEmoji ?? '🤔',
          isVerdict: false,
          scoreDelta: 0,
        );
      }
      return result;
    }

    try {
      final json = _parseJsonFromResponse(text);
      final commentary = json['commentary'] as String?;
      final trimmed = commentary?.trim() ?? '';
      return JudgeResponse(
        score: 0,
        isUnlocked: false,
        commentary: trimmed.isNotEmpty && trimmed.length > 2
            ? trimmed
            : _randomFallback(),
        hint: null,
        moodEmoji: json['mood_emoji'] as String? ?? '🤔',
        isVerdict: false,
        scoreDelta: (json['score_delta'] as int?)?.clamp(-20, 20) ?? 0,
      );
    } catch (e, st) {
      assert(() {
        debugPrint('Judge parse failed: $e');
        debugPrint('Raw response: $text');
        debugPrint('Stack: $st');
        return true;
      }());
      return JudgeResponse(
        score: 0,
        isUnlocked: false,
        commentary: 'The judge is speechless.',
        hint: null,
        moodEmoji: '😶',
        scoreDelta: 0,
      );
    }
  }

  /// Returns one short, non-revealing hint for the surprise (e.g. for paid hint). Uses judge in hint-only mode.
  Future<String> getHint({
    required String persona,
    required int difficultyLevel,
    String? surpriseContextHint,
  }) async {
    final hintRequest = [
      BattleMessage(
        id: 'hint-req',
        surpriseId: '',
        senderType: 'seeker',
        senderId: null,
        content: 'Give me one short, non-revealing hint to help me unlock this surprise. Do not reveal the content.',
        isVerdict: false,
        verdictScore: null,
        verdictUnlocked: null,
        createdAt: DateTime.now(),
      ),
    ];
    final response = await judgeChat(
      persona: persona,
      difficultyLevel: difficultyLevel,
      messages: hintRequest,
      surpriseContextHint: surpriseContextHint ?? 'romantic surprise',
      howToImpressHint: null,
    );
    return response.commentary;
  }

  /// Parses JSON from model output. Tolerates markdown code fences and surrounding text.
  static Map<String, dynamic> _parseJsonFromResponse(String text) {
    if (text.isEmpty) return {};
    var raw = text.trim();
    // Strip markdown code block if present
    if (raw.startsWith('```')) {
      raw = raw.replaceFirst(RegExp(r'^```\w*\n?'), '').replaceFirst(RegExp(r'\n?```\s*$'), '');
    }
    raw = raw.trim();
    if (raw.isEmpty) return {};
    // Extract JSON object: find first { and matching last }
    final start = raw.indexOf('{');
    if (start == -1) return {};
    int depth = 0;
    int end = -1;
    for (int i = start; i < raw.length; i++) {
      if (raw[i] == '{') depth++;
      if (raw[i] == '}') {
        depth--;
        if (depth == 0) {
          end = i;
          break;
        }
      }
    }
    if (end == -1) return {};
    final jsonStr = raw.substring(start, end + 1);
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }
}
