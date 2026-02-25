class JudgeResponse {
  const JudgeResponse({
    required this.score,
    required this.isUnlocked,
    required this.commentary,
    this.hint,
    this.moodEmoji,
    this.isVerdict = false,
  });

  final int score;
  final bool isUnlocked;
  /// True when the judge delivered a final verdict (unlock or deny); false for mid-chat commentary only.
  final bool isVerdict;
  final String commentary;
  final String? hint;
  final String? moodEmoji;

  factory JudgeResponse.fromJson(Map<String, dynamic> json) {
    final hasVerdict = json.containsKey('score') && json.containsKey('is_unlocked');
    return JudgeResponse(
      score: (json['score'] as int?) ?? 0,
      isUnlocked: (json['is_unlocked'] as bool?) ?? false,
      commentary: (json['commentary'] as String?) ?? '',
      hint: json['hint'] as String?,
      moodEmoji: json['mood_emoji'] as String?,
      isVerdict: (json['is_verdict'] as bool?) ?? hasVerdict,
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
