class CustomJudge {
  const CustomJudge({
    required this.id,
    required this.coupleId,
    required this.personalityName,
    required this.personalityQuery,
    required this.mood,
    required this.generatedPersonaPrompt,
    this.generatedHowToImpress,
    this.previewQuotes = const [],
    this.avatarStoragePath,
    this.avatarEmoji = '🎭',
    required this.difficultyLevel,
    required this.chaosLevel,
    required this.isPublished,
    required this.useCount,
    required this.isFlagged,
    required this.isActiveForBattle,
    required this.createdAt,
  });

  final String id;
  final String coupleId;
  final String personalityName;
  final String personalityQuery;
  final String mood;
  final String generatedPersonaPrompt;
  final String? generatedHowToImpress;
  final List<String> previewQuotes;
  final String? avatarStoragePath;
  final String avatarEmoji;
  final int difficultyLevel;
  final int chaosLevel;
  final bool isPublished;
  final int useCount;
  final bool isFlagged;
  final bool isActiveForBattle;
  final DateTime createdAt;

  factory CustomJudge.fromJson(Map<String, dynamic> json) {
    List<String> quotes = [];
    final raw = json['preview_quotes'];
    if (raw is List) {
      quotes = raw.cast<String>();
    }

    return CustomJudge(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      personalityName: json['personality_name'] as String,
      personalityQuery: json['personality_query'] as String,
      mood: (json['mood'] as String?) ?? 'funny',
      generatedPersonaPrompt: json['generated_persona_prompt'] as String,
      generatedHowToImpress: json['generated_how_to_impress'] as String?,
      previewQuotes: quotes,
      avatarStoragePath: json['avatar_storage_path'] as String?,
      avatarEmoji: (json['avatar_emoji'] as String?) ?? '🎭',
      difficultyLevel: json['difficulty_level'] as int? ?? 2,
      chaosLevel: json['chaos_level'] as int? ?? 2,
      isPublished: json['is_published'] as bool? ?? false,
      useCount: json['use_count'] as int? ?? 0,
      isFlagged: json['is_flagged'] as bool? ?? false,
      isActiveForBattle: json['is_active_for_battle'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'personality_name': personalityName,
      'personality_query': personalityQuery,
      'mood': mood,
      'generated_persona_prompt': generatedPersonaPrompt,
      'generated_how_to_impress': generatedHowToImpress,
      'preview_quotes': previewQuotes,
      'avatar_storage_path': avatarStoragePath,
      'avatar_emoji': avatarEmoji,
      'difficulty_level': difficultyLevel,
      'chaos_level': chaosLevel,
      'is_published': isPublished,
      'use_count': useCount,
      'is_flagged': isFlagged,
      'is_active_for_battle': isActiveForBattle,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get moodDisplayName {
    switch (mood) {
      case 'funny': return 'Funny';
      case 'savage': return 'Savage';
      case 'romantic': return 'Romantic';
      case 'strict': return 'Strict';
      case 'chaotic': return 'Chaotic';
      case 'chill': return 'Chill';
      default: return mood;
    }
  }
}
