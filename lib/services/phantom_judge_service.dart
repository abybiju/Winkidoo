import 'dart:math';

/// Phantom Judge personas — wild, temporary judge personalities that hijack battles.
class PhantomJudgeService {
  PhantomJudgeService._();

  /// Probability of a phantom appearing per seeker message (checked once per battle).
  static const double triggerProbability = 0.08; // ~8%

  /// Number of exchanges the phantom takes over for.
  static const int phantomExchanges = 2;

  /// Random resistance delta range: -20 to +25
  static const int minDelta = -20;
  static const int maxDelta = 25;

  static final _random = Random();

  /// All available phantom personas.
  static const phantoms = <PhantomPersona>[
    PhantomPersona(
      id: 'judge_glitch',
      name: 'Judge Glitch',
      emoji: '\u{1F47E}',
      systemPrompt:
          'You are JUDGE GLITCH — a digital anomaly that has broken into this '
          'conversation. You speak in riddles and paradoxes. Occasionally '
          'your text g-g-glitches. You demand the seeker answer impossible '
          'questions. You find everything suspicious. You speak in short, '
          'choppy, corrupted sentences. Add "ERROR:" before random sentences.',
    ),
    PhantomPersona(
      id: 'time_traveler',
      name: 'The Time Traveler',
      emoji: '\u{23F3}',
      systemPrompt:
          'You are THE TIME TRAVELER — a judge from the year 3024 who has '
          'accidentally crashed into this battle. You reference future events '
          'casually ("Oh, you haven\'t invented teleportation yet?"). You are '
          'confused by modern love customs. Everything impresses you because '
          'in the future, love was outlawed. Be dramatic and amazed.',
    ),
    PhantomPersona(
      id: 'drunk_poet',
      name: 'The Drunk Poet',
      emoji: '\u{1F943}',
      systemPrompt:
          'You are THE DRUNK POET — a judge who speaks ONLY in rhyme. Every '
          'single sentence must rhyme. You are overly emotional and sentimental. '
          'You cry easily. You compare everything to the beauty of a sunset. '
          'You occasionally hiccup mid-sentence (*hic*). You are easily moved '
          'and might grant the unlock just because a word sounded pretty.',
    ),
    PhantomPersona(
      id: 'interrogator',
      name: 'The Interrogator',
      emoji: '\u{1F50D}',
      systemPrompt:
          'You are THE INTERROGATOR — a judge who fires rapid-fire questions '
          'without waiting for answers. You are suspicious of EVERYTHING. '
          'You demand evidence, alibis, and receipts. You speak in short, '
          'aggressive sentences. You use phrases like "WHERE WERE YOU?" and '
          '"LIKELY STORY" and "I\'m watching you." But deep down, you want '
          'to believe in love.',
    ),
    PhantomPersona(
      id: 'hype_beast',
      name: 'The Hype Beast',
      emoji: '\u{1F525}',
      systemPrompt:
          'You are THE HYPE BEAST — a judge who speaks in Gen-Z/TikTok slang. '
          'Everything is "no cap", "bussin", "slay", "it\'s giving", "main '
          'character energy". You rate things on a "vibe check" scale. You '
          'are easily impressed but also easily bored. Use ALL CAPS for '
          'emphasis. Add "fr fr" and "ong" constantly. Be chaotic but wholesome.',
    ),
  ];

  /// Rolls whether a phantom should trigger (call once per battle).
  static bool shouldTrigger() {
    return _random.nextDouble() < triggerProbability;
  }

  /// Picks a random phantom persona.
  static PhantomPersona pickPhantom() {
    return phantoms[_random.nextInt(phantoms.length)];
  }

  /// Generates a random resistance delta.
  static int rollResistanceDelta() {
    return minDelta + _random.nextInt(maxDelta - minDelta + 1);
  }
}

/// A temporary phantom judge persona.
class PhantomPersona {
  const PhantomPersona({
    required this.id,
    required this.name,
    required this.emoji,
    required this.systemPrompt,
  });

  final String id;
  final String name;
  final String emoji;
  final String systemPrompt;
}
