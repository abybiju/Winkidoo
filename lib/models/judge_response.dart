class JudgeResponse {
  const JudgeResponse({
    required this.score,
    required this.isUnlocked,
    required this.commentary,
    this.hint,
    this.moodEmoji,
  });

  final int score;
  final bool isUnlocked;
  final String commentary;
  final String? hint;
  final String? moodEmoji;

  factory JudgeResponse.fromJson(Map<String, dynamic> json) {
    return JudgeResponse(
      score: json['score'] as int,
      isUnlocked: json['is_unlocked'] as bool,
      commentary: json['commentary'] as String,
      hint: json['hint'] as String?,
      moodEmoji: json['mood_emoji'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'is_unlocked': isUnlocked,
      'commentary': commentary,
      'hint': hint,
      'mood_emoji': moodEmoji,
    };
  }
}
