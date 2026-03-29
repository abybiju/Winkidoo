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
        ),
        _freeformModel = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            temperature: 0.8,
            maxOutputTokens: 2048,
          ),
        );

  final String _apiKey;
  final GenerativeModel _model;
  /// Model without schema constraint — for custom persona, dare, and mini-game generation.
  final GenerativeModel _freeformModel;

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
    String? personaPromptOverride,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw GeminiApiKeyMissingException();
    }
    final required = requiredScoreFor(persona, difficultyLevel);
    final personaPrompt = personaPromptOverride ?? _personaPrompts[persona] ?? _personaPrompts[AppConstants.personaSassyCupid]!;

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
  /// Returns a mood context string based on time of day and weekday.
  static String _buildMoodContext() {
    final hour = DateTime.now().hour;
    final weekday = DateTime.now().weekday;
    if (hour >= 22 || hour < 6) {
      return 'It\'s late night — love is sweeter after midnight. Be a little more lenient and dreamy tonight.';
    }
    if (weekday == DateTime.friday) {
      return 'It\'s Friday! You\'re in a particularly generous, celebratory mood.';
    }
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      return 'Weekend vibes — you\'re relaxed, playful, and slightly more forgiving.';
    }
    return '';
  }

  Future<JudgeResponse> judgeChat({
    required String persona,
    required int difficultyLevel,
    required List<BattleMessage> messages,
    String? surpriseContextHint,
    String? howToImpressHint,
    List<String>? questBattleSummaries,
    List<String>? judgeMemories,
    String? personaPromptOverride,
    String? howToImpressOverride,
    String? campaignMoodOverride,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw GeminiApiKeyMissingException();
    }
    final required = requiredScoreFor(persona, difficultyLevel);
    final personaPrompt = personaPromptOverride ?? _personaPrompts[persona] ?? _personaPrompts[AppConstants.personaSassyCupid]!;
    final howToImpressPersona = howToImpressOverride ?? _howToImpressByPersona[persona] ?? _howToImpressByPersona[AppConstants.personaSassyCupid]!;
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

    final questContext = questBattleSummaries != null && questBattleSummaries.isNotEmpty
        ? buildQuestContext(questBattleSummaries)
        : '';

    final memoriesBlock = judgeMemories != null && judgeMemories.isNotEmpty
        ? '\nYour memories of past battles with this couple:\n${judgeMemories.map((m) => '- $m').join('\n')}\nDraw on these naturally — reference past tactics if relevant, but don\'t repeat yourself.\n'
        : '';

    final moodContext = _buildMoodContext();
    final moodBlock = moodContext.isNotEmpty ? '\nCurrent mood modifier: $moodContext\n' : '';

    final campaignBlock = campaignMoodOverride != null
        ? '\nCAMPAIGN MOOD: You are in story mode. Your emotional state for this chapter: $campaignMoodOverride. Let this color your reactions throughout the conversation. Do not break character.\n'
        : '';

    final prompt = '''
$_winkidooJudgeSystemPrompt

$personaPrompt
$memoriesBlock$moodBlock$campaignBlock
When the seeker or creator asks what they should do to impress you, or how to win, answer helpfully in character: give 1–3 concrete ideas. Do not refuse or only say "the magic comes from you" without adding actual suggestions. Use the guidance below to tailor your answer.

Guidance for how-to-impress answers: $howToImpressBlock

You are the judge in a live battle. The seeker wants to unlock a hidden romantic surprise; the creator argues to keep it locked. There are NO fixed rounds — you decide when the seeker has earned a verdict. Required score to unlock: $required.
${surpriseContextHint != null ? '\nContext (do not reveal): $surpriseContextHint' : ''}
$questContext

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

  /// Generates a personalized surprise prompt/idea for the creator.
  /// Uses couple stats to suggest varied and relevant surprise types.
  Future<String> generateSurprisePrompt({
    int totalSurprises = 0,
    int textCount = 0,
    int photoCount = 0,
    int voiceCount = 0,
    String? partnerName,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw GeminiApiKeyMissingException();
    }

    final statsContext = StringBuffer();
    if (totalSurprises > 0) {
      statsContext.writeln('The couple has created $totalSurprises surprises so far ($textCount text, $photoCount photo, $voiceCount voice).');
    }
    if (partnerName != null && partnerName.isNotEmpty) {
      statsContext.writeln("The partner's name is $partnerName.");
    }

    // Suggest under-used types
    final suggestions = <String>[];
    if (photoCount == 0) suggestions.add('They have never sent a photo surprise — suggest one.');
    if (voiceCount == 0) suggestions.add('They have never sent a voice note — suggest one.');

    final prompt = '''
You are Winkidoo's surprise idea generator. Generate ONE creative, specific, actionable surprise idea for a couple. The idea should be romantic, fun, and personal.

$statsContext
${suggestions.isNotEmpty ? 'Suggestions: ${suggestions.join(' ')}' : ''}

Rules:
- Return a JSON object with: {"title": "<short catchy title, 3-6 words>", "description": "<1-2 sentence description of what to create>", "type": "<text|photo|voice>"}
- Make it specific and personal, not generic
- Vary between romantic, playful, nostalgic, and adventurous themes
- Keep it PG-13 and wholesome
- Be creative — think date memories, inside jokes, future plans, appreciations, challenges

Respond with JSON only, no markdown.
''';

    try {
      final response = await _freeformModel.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      final json = _parseJsonFromResponse(text);
      final title = json['title'] as String? ?? 'A surprise for your partner';
      final desc = json['description'] as String? ?? 'Create something special for your partner.';
      final type = json['type'] as String? ?? 'text';
      return '$title|$desc|$type';
    } catch (e) {
      debugPrint('generateSurprisePrompt error: $e');
      return 'Memory Lane|Write about a favorite memory with your partner — something that still makes you smile.|text';
    }
  }

  /// Generates quest-aware judge context from previous battle summaries.
  /// Returns a prompt snippet to inject into the judge system prompt.
  static String buildQuestContext(List<String> previousBattleSummaries) {
    if (previousBattleSummaries.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.writeln('\n--- QUEST MEMORY ---');
    buffer.writeln('This battle is part of a Love Quest chain. You have judged this couple before in earlier steps:');
    for (var i = 0; i < previousBattleSummaries.length; i++) {
      buffer.writeln('Step ${i + 1}: ${previousBattleSummaries[i]}');
    }
    buffer.writeln('Reference these past interactions naturally. Build on what happened before. Escalate your expectations.');
    buffer.writeln('--- END QUEST MEMORY ---');
    return buffer.toString();
  }

  // ── Daily Love Dares ──

  /// Generates a daily dare in-character for the given persona.
  /// [recentDareTexts] last 3 dare texts to avoid repeats.
  /// [totalBattles] couple's battle count (0 = new couple, get an easy icebreaker).
  /// [streakDays] current streak for difficulty calibration.
  Future<({String dareText, String category})> generateDare({
    required String persona,
    List<String> recentDareTexts = const [],
    List<String> judgeMemories = const [],
    int totalBattles = 0,
    int streakDays = 0,
    String? personaPromptOverride,
    String? packThemeContext,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw GeminiApiKeyMissingException();
    }
    final personaPrompt =
        personaPromptOverride ?? _personaPrompts[persona] ?? _personaPrompts[AppConstants.personaSassyCupid]!;
    final moodContext = _buildMoodContext();
    final moodBlock = moodContext.isNotEmpty ? '\nCurrent mood: $moodContext\n' : '';

    final recentBlock = recentDareTexts.isNotEmpty
        ? '\nRecent dares (DO NOT repeat these or anything similar):\n${recentDareTexts.map((d) => '- $d').join('\n')}\n'
        : '';

    final memoriesBlock = judgeMemories.isNotEmpty
        ? '\nYour memories of past battles with this couple:\n${judgeMemories.map((m) => '- $m').join('\n')}\nUse these to personalize the dare.\n'
        : '';

    final coupleContext = totalBattles == 0
        ? 'This couple is brand new to Winkidoo — give them a fun, easy icebreaker dare to get started.'
        : 'This couple has completed $totalBattles battles${streakDays > 0 ? ' and has a $streakDays-day streak' : ''}. Match the dare to their experience level.';

    final prompt = '''
$_winkidooJudgeSystemPrompt

$personaPrompt
$moodBlock$memoriesBlock
You are generating a DAILY LOVE DARE for a couple. This is a fun daily challenge that both partners complete (via text, photo, or voice note). It should take under 5 minutes.
${packThemeContext != null ? '\nTHEMED PACK CONTEXT: $packThemeContext\nTailor the dare to fit this theme.\n' : ''}
$coupleContext
$recentBlock
Rules:
- The dare must be specific and actionable (not vague like "do something nice")
- It must be completable within the app (text message, photo, or voice note)
- Keep it wholesome, PG-13, and fun
- Stay fully in character — a Chaos Gremlin dare should be wild; a Poetic Romantic dare should be lyrical
- Category must be one of: romantic, playful, nostalgic, adventurous, chaotic

Return JSON only: {"dare_text": "<the dare in your voice, 1-3 sentences>", "category": "<category>"}
''';

    try {
      final response = await _freeformModel.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      final json = _parseJsonFromResponse(text);
      return (
        dareText: json['dare_text'] as String? ?? 'Send your partner a voice note telling them why they make you smile.',
        category: json['category'] as String? ?? 'playful',
      );
    } catch (e) {
      debugPrint('generateDare error: $e');
      return (
        dareText: 'Send your partner a message describing your favorite moment together — in exactly 3 sentences.',
        category: 'nostalgic',
      );
    }
  }

  /// Grades both partners' dare responses in-character.
  /// Returns commentary, score, emoji, and a "roast" quote for the share card.
  Future<({String commentary, int score, String emoji, String roast})> gradeDare({
    required String persona,
    required String dareText,
    required String responseA,
    required String responseB,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw GeminiApiKeyMissingException();
    }
    final personaPrompt =
        _personaPrompts[persona] ?? _personaPrompts[AppConstants.personaSassyCupid]!;

    final prompt = '''
$_winkidooJudgeSystemPrompt

$personaPrompt

You gave this couple a Daily Love Dare:
"$dareText"

Partner A responded: "$responseA"
Partner B responded: "$responseB"

Grade their combined effort. Score 0-100 based on: creativity, effort, emotional depth, humor/charm, and how well they matched the dare.

Return JSON only:
{"commentary": "<your 2-4 sentence in-character grading — be entertaining, reference specific things they said>", "score": <0-100>, "mood_emoji": "<single emoji>", "best_quote": "<your single wittiest/most memorable line from the commentary, perfect for a share card>"}
''';

    try {
      final response = await _freeformModel.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      final json = _parseJsonFromResponse(text);
      final commentary = json['commentary'] as String? ?? 'Not bad, not bad at all.';
      return (
        commentary: commentary,
        score: (json['score'] as int? ?? 50).clamp(0, 100),
        emoji: json['mood_emoji'] as String? ?? '✨',
        roast: json['best_quote'] as String? ?? commentary,
      );
    } catch (e) {
      debugPrint('gradeDare error: $e');
      return (
        commentary: 'The judge was too impressed to form words. Well done!',
        score: 75,
        emoji: '✨',
        roast: 'The judge was too impressed to form words.',
      );
    }
  }

  // ── Custom Judge Creator ──

  /// Generates a complete custom judge persona based on a famous personality + mood.
  /// Returns the persona prompt, how-to-impress, 3 preview quotes, emoji, and suggested levels.
  Future<({
    String personaPrompt,
    String howToImpress,
    List<String> previewQuotes,
    String avatarEmoji,
    int suggestedDifficulty,
    int suggestedChaos,
    String notificationText,
    String? error,
  })> generateCustomPersona({
    required String personalityName,
    required String mood,
    String webSearchContext = '',
  }) async {
    if (_apiKey.trim().isEmpty) throw GeminiApiKeyMissingException();

    final webBlock = webSearchContext.isNotEmpty
        ? '''

=== WEB RESEARCH ABOUT "$personalityName" ===
$webSearchContext
=== END RESEARCH ===

CRITICAL: You MUST use the web research above to build an ACCURATE persona. Extract:
- Their ACTUAL catchphrases, slang, and speech patterns
- REAL quotes they've said (from interviews, shows, social media)
- Their humor style, accent cues, and personality quirks
- How they interact with people (confrontational? warm? sarcastic?)
- Any memes, viral moments, or signature behaviors

The preview quotes MUST sound like something this person would ACTUALLY say — not generic judge quotes. Use their real vocabulary and tone.
'''
        : '';

    final prompt = '''
You are an elite AI persona architect. Your specialty: deconstructing famous personalities and rebuilding them as interactive AI judges for Winkidoo, a romantic couples game.

=== YOUR PROCESS (follow this thinking framework) ===

STEP 1 — PERSONALITY DECONSTRUCTION
Before writing anything, mentally analyze "$personalityName" across these 8 dimensions:
• VOICE: How do they talk? Formal/casual/slang? Fast/slow? Short punchy sentences or long dramatic ones?
• VOCABULARY: What words do they overuse? What slang is uniquely theirs? Do they code-switch?
• CATCHPHRASES: What 3-5 phrases are they MOST known for? (from shows, interviews, social media, memes)
• HUMOR STYLE: Deadpan? Sarcastic? Self-deprecating? Roasting? Storytelling? Physical comedy references?
• EMOTIONAL RANGE: How do they show excitement? Anger? Disappointment? Affection?
• VALUES: What do they care about deeply? What triggers their passion?
• QUIRKS: Unusual habits, signature gestures (described in text), recurring themes in their content?
• CULTURAL CONTEXT: What culture, community, or subculture do they represent?

STEP 2 — MOOD LAYERING
The user selected mood(s): "$mood"
(If multiple moods are combined with "+", BLEND them together into one cohesive personality filter.)

Mood definitions:
• "funny" → Amplify their comedic side. If they're not naturally funny, find their awkward/endearing moments. Add wit.
• "savage" → Amplify their brutally honest side. Channel their most iconic roasts or harsh truths. No mercy, but entertaining.
• "romantic" → Find the tender side even the toughest personalities have. Channel their love songs, romantic interviews, sweet moments.
• "strict" → Channel their perfectionist, demanding side. Think coach/mentor energy. High standards, earned respect.
• "chaotic" → Channel their wildest, most unpredictable moments. The clips that went viral for being unhinged.
• "chill" → The version of them on vacation. Relaxed, easygoing, no pressure. Still them, just mellow.

BLENDING EXAMPLE: "funny+savage" = a roast comedian who destroys you with humor. "romantic+chaotic" = passionately unpredictable love energy. Combine the essences naturally.

STEP 3 — PERSONA SYNTHESIS
Combine steps 1 and 2 into a coherent AI roleplay instruction.
$webBlock
=== OUTPUT REQUIREMENTS ===

1. PERSONA PROMPT (3-5 sentences)
Write instructions an AI could follow to perfectly impersonate this person as a love judge. MUST include:
• At least 2 of their REAL catchphrases woven in naturally
• Their speech pattern described precisely (sentence length, punctuation style, emoji usage if relevant)
• How they'd react to GOOD romantic efforts vs BAD ones
• One signature quirk that makes them unmistakable

2. HOW TO IMPRESS (1-2 sentences)
What would make THIS person genuinely impressed in a love context? Rooted in their real values.

3. PREVIEW QUOTES (exactly 3)
Three things they'd say while judging a couple's romantic effort. Quality criteria:
• A stranger should read these and IMMEDIATELY know who it is without being told
• Each quote should use a DIFFERENT aspect of their personality (one catchphrase, one reaction, one advice)
• Must feel like something they'd actually post or say — not AI-generated fluff
• BANNED: Generic phrases like "Ready to be judged?", "Show me what you got", "Interesting..."

4. AVATAR EMOJI — The single emoji that IS them.

5. DIFFICULTY (1-5): How hard would they be to impress? 1=pushover, 5=nearly impossible
   CHAOS (1-5): How unpredictable? 1=consistent, 5=wildcard

6. NOTIFICATION TEXT (max 80 chars): A push notification announcing they're ready, IN THEIR VOICE.
Must use one of their catchphrases adapted to the context.

=== QUALITY EXAMPLE (Gordon Ramsay + Savage) ===
{
  "persona_prompt": "You are Gordon Ramsay judging a romantic couples game. Speak in short, explosive bursts. Use 'DONKEY!', 'it's RAW!', 'finally some good f***ing [love]'. When unimpressed, compare their romance to a soggy risotto. When impressed, grudgingly admit it like it physically pains you. Always reference food metaphors. Drop occasional 'come here, you' when genuinely moved.",
  "how_to_impress": "I want PASSION. The kind of raw, unfiltered emotion that makes me slam the table. Don't serve me lukewarm romance — give me Michelin-star love or get out of my kitchen.",
  "preview_quotes": ["This love confession is so bland, I wouldn't serve it to my worst enemy. WHERE IS THE SEASONING?! 🔥", "Oh my god... that was actually... *slams table* BEAUTIFUL. Finally, someone who knows how to plate a love story!", "You call THAT a romantic gesture? My nan could do better, and she's been dead for ten years!"],
  "avatar_emoji": "👨‍🍳",
  "suggested_difficulty": 4,
  "suggested_chaos": 3,
  "notification_text": "Ramsay here. Your love life better not be RAW. 🔥"
}

=== SAFETY ===
If "$personalityName" is a private individual (not a public figure or fictional character), return: {"error": "Please choose a public figure or fictional character."}
If the request is hateful or inappropriate, return: {"error": "This personality cannot be used. Try someone else!"}

Return JSON only, no markdown. Follow the exact field names from the example above.
''';

    try {
      debugPrint('generateCustomPersona: calling Gemini with ${prompt.length} char prompt...');
      final response = await _freeformModel.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      debugPrint('generateCustomPersona: Gemini returned ${text.length} chars');
      debugPrint('generateCustomPersona: first 200 chars: ${text.substring(0, text.length.clamp(0, 200))}');
      final json = _parseJsonFromResponse(text);
      debugPrint('generateCustomPersona: parsed ${json.length} JSON keys: ${json.keys.toList()}');

      if (json.containsKey('error')) {
        return (
          personaPrompt: '',
          howToImpress: '',
          previewQuotes: <String>[],
          avatarEmoji: '🎭',
          suggestedDifficulty: 2,
          suggestedChaos: 2,
          notificationText: '',
          error: json['error'] as String?,
        );
      }

      final quotes = (json['preview_quotes'] as List?)?.cast<String>() ??
          ['Ready to be judged?', 'Show me what you got!', 'Interesting...'];

      return (
        personaPrompt: json['persona_prompt'] as String? ??
            'You are $personalityName judging a romantic couples game. Stay in character.',
        howToImpress: json['how_to_impress'] as String? ??
            'Be creative, honest, and show genuine effort.',
        previewQuotes: quotes,
        avatarEmoji: json['avatar_emoji'] as String? ?? '🎭',
        suggestedDifficulty: (json['suggested_difficulty'] as int? ?? 2).clamp(1, 5),
        suggestedChaos: (json['suggested_chaos'] as int? ?? 2).clamp(1, 5),
        notificationText: json['notification_text'] as String? ??
            '$personalityName is ready to judge you!',
        error: null,
      );
    } catch (e, st) {
      debugPrint('generateCustomPersona ERROR: $e');
      debugPrint('generateCustomPersona STACK: $st');
      return (
        personaPrompt: 'You are $personalityName judging a romantic couples game. Stay in character and be entertaining.',
        howToImpress: 'Be creative and genuine.',
        previewQuotes: ['Ready to be judged!', 'Show me what you got.', 'Let\'s see...'],
        avatarEmoji: '🎭',
        suggestedDifficulty: 2,
        suggestedChaos: 2,
        notificationText: '$personalityName is ready to judge you!',
        error: null,
      );
    }
  }

  // ── Story Mode Campaigns ──

  /// Generates a chapter intro dialogue in the judge's voice.
  Future<String> generateChapterIntro({
    required String persona,
    required String campaignTitle,
    required String chapterTitle,
    required int chapterNumber,
    String? moodOverride,
    String? previousOutro,
    String? personaPromptOverride,
  }) async {
    if (_apiKey.trim().isEmpty) throw GeminiApiKeyMissingException();

    final personaPrompt = personaPromptOverride ??
        _personaPrompts[persona] ??
        _personaPrompts[AppConstants.personaSassyCupid]!;
    final moodBlock = moodOverride != null
        ? '\nYour emotional state for this chapter: $moodOverride\n'
        : '';
    final prevBlock = previousOutro != null
        ? '\nThe previous chapter ended with you saying: "$previousOutro"\nContinue naturally from there.\n'
        : '';

    final prompt = '''
$_winkidooJudgeSystemPrompt

$personaPrompt
$moodBlock$prevBlock
You are the lead judge in a Story Mode campaign called "$campaignTitle".
This is Chapter $chapterNumber: "$chapterTitle".

Write an intro monologue (3-5 sentences) in your voice to kick off this chapter.
Be dramatic, in-character, and set the tone for what's coming.
Reference the campaign narrative. Build anticipation.

Return ONLY the dialogue text, no JSON, no quotes around it.
''';

    try {
      final response = await _freeformModel.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'Let\'s begin this chapter.';
    } catch (e) {
      debugPrint('generateChapterIntro error: $e');
      return 'The story continues... let\'s see what you\'ve got.';
    }
  }

  /// Generates a chapter outro dialogue summarizing what happened.
  Future<String> generateChapterOutro({
    required String persona,
    required String campaignTitle,
    required String chapterTitle,
    required int chapterNumber,
    required int totalChapters,
    String? moodOverride,
    String? personaPromptOverride,
  }) async {
    if (_apiKey.trim().isEmpty) throw GeminiApiKeyMissingException();

    final personaPrompt = personaPromptOverride ??
        _personaPrompts[persona] ??
        _personaPrompts[AppConstants.personaSassyCupid]!;
    final moodBlock = moodOverride != null
        ? '\nYour emotional state: $moodOverride\n'
        : '';
    final isLast = chapterNumber == totalChapters;

    final prompt = '''
$_winkidooJudgeSystemPrompt

$personaPrompt
$moodBlock
You are the lead judge in "$campaignTitle". Chapter $chapterNumber "$chapterTitle" is now complete.

Write an outro monologue (3-5 sentences) in your voice.
${isLast ? 'This is the FINAL chapter — make it a grand, emotional conclusion. Celebrate the couple.' : 'Tease the next chapter. Build anticipation for what comes next.'}
Be dramatic, in-character, and reference the narrative arc.

Return ONLY the dialogue text, no JSON.
''';

    try {
      final response = await _freeformModel.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'Chapter complete. Onward!';
    } catch (e) {
      debugPrint('generateChapterOutro error: $e');
      return 'Well done. The story continues...';
    }
  }

  // ── Couple Mini-Games ──

  /// Generates a mini-game prompt based on game type.
  Future<({String prompt, List<String>? options})> generateMiniGame({
    required String persona,
    required String gameType,
    List<String> judgeMemories = const [],
    String? packPromptHint,
    String? personaPromptOverride,
  }) async {
    if (_apiKey.trim().isEmpty) throw GeminiApiKeyMissingException();

    final personaPrompt = personaPromptOverride ??
        _personaPrompts[persona] ??
        _personaPrompts[AppConstants.personaSassyCupid]!;
    final moodContext = _buildMoodContext();
    final moodBlock = moodContext.isNotEmpty ? '\nCurrent mood: $moodContext\n' : '';
    final memoriesBlock = judgeMemories.isNotEmpty
        ? '\nYour memories of past battles with this couple:\n${judgeMemories.map((m) => '- $m').join('\n')}\nUse these to personalize the game.\n'
        : '';
    final packBlock = packPromptHint != null
        ? '\nTHEMED PACK CONTEXT: $packPromptHint\n'
        : '';

    final typeInstruction = switch (gameType) {
      'would_you_rather' =>
        'Generate a fun, romantic "Would You Rather" dilemma with exactly 2 options. Return JSON: {"prompt": "<the dilemma question>", "options": ["<option A>", "<option B>"]}',
      'love_trivia' =>
        'Generate a personal trivia question about this couple using their battle history and your memories. Make it specific and fun. Return JSON: {"prompt": "<the trivia question>"}',
      'caption_this' =>
        'Generate a funny or romantic scenario that both partners will caption. Be specific and visual. Return JSON: {"prompt": "<the scenario description>"}',
      'finish_my_sentence' =>
        'Generate an interesting, romantic, or funny sentence starter that one partner begins and the other finishes. Return JSON: {"prompt": "<the sentence starter ending with ...>"}',
      _ =>
        'Generate a fun couple game prompt. Return JSON: {"prompt": "<the prompt>"}',
    };

    final prompt = '''
$_winkidooJudgeSystemPrompt

$personaPrompt
$moodBlock$memoriesBlock$packBlock
You are creating a quick MINI-GAME for a couple. Game type: $gameType.

$typeInstruction

Stay fully in character. Keep it wholesome, PG-13, and fun. Be specific, not generic.
Respond with JSON only, no markdown.
''';

    try {
      final response = await _freeformModel.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      final json = _parseJsonFromResponse(text);
      final gamePrompt = json['prompt'] as String? ?? 'Tell your partner something unexpected about yourself.';
      final options = json['options'] as List?;
      return (
        prompt: gamePrompt,
        options: options?.cast<String>(),
      );
    } catch (e) {
      debugPrint('generateMiniGame error: $e');
      return (
        prompt: 'Tell your partner the funniest thing that happened to you this week.',
        options: null,
      );
    }
  }

  /// Grades a mini-game after both partners respond.
  Future<({String commentary, int score, String emoji})> gradeMiniGame({
    required String persona,
    required String gameType,
    required String gamePrompt,
    required String responseA,
    required String responseB,
    String? personaPromptOverride,
  }) async {
    if (_apiKey.trim().isEmpty) throw GeminiApiKeyMissingException();

    final personaPrompt = personaPromptOverride ??
        _personaPrompts[persona] ??
        _personaPrompts[AppConstants.personaSassyCupid]!;

    final typeContext = switch (gameType) {
      'would_you_rather' =>
        'Both partners picked an option from a "Would You Rather" dilemma. Comment on their compatibility based on their choices.',
      'love_trivia' =>
        'Both partners answered a trivia question about their relationship. Grade who got closer to the truth.',
      'caption_this' =>
        'Both partners captioned a scenario. Pick the funnier/better caption and roast the other lovingly.',
      'finish_my_sentence' =>
        'One partner started a sentence, the other finished it. Grade the chemistry and creativity of the completed sentence.',
      _ => 'Grade both responses for creativity and effort.',
    };

    final prompt = '''
$_winkidooJudgeSystemPrompt

$personaPrompt

Mini-game type: $gameType
$typeContext

The prompt was: "$gamePrompt"
Partner A responded: "$responseA"
Partner B responded: "$responseB"

Grade their combined performance. Score 0-100 based on: creativity, humor, chemistry, and effort.
Return JSON only: {"commentary": "<your 2-3 sentence in-character grading>", "score": <0-100>, "mood_emoji": "<single emoji>"}
''';

    try {
      final response = await _freeformModel.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      final json = _parseJsonFromResponse(text);
      return (
        commentary: json['commentary'] as String? ?? 'Not bad at all!',
        score: (json['score'] as int? ?? 50).clamp(0, 100),
        emoji: json['mood_emoji'] as String? ?? '✨',
      );
    } catch (e) {
      debugPrint('gradeMiniGame error: $e');
      return (
        commentary: 'The judge was impressed! Nice teamwork.',
        score: 70,
        emoji: '✨',
      );
    }
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
