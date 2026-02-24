class Surprise {
  const Surprise({
    required this.id,
    required this.coupleId,
    required this.creatorId,
    required this.contentEncrypted,
    required this.unlockMethod,
    required this.judgePersona,
    required this.difficultyLevel,
    this.autoDeleteAt,
    required this.isUnlocked,
    this.unlockedAt,
    required this.createdAt,
  });

  final String id;
  final String coupleId;
  final String creatorId;
  final String contentEncrypted;
  final String unlockMethod;
  final String judgePersona;
  final int difficultyLevel;
  final DateTime? autoDeleteAt;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final DateTime createdAt;

  factory Surprise.fromJson(Map<String, dynamic> json) {
    return Surprise(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      creatorId: json['creator_id'] as String,
      contentEncrypted: json['content_encrypted'] as String,
      unlockMethod: json['unlock_method'] as String,
      judgePersona: json['judge_persona'] as String,
      difficultyLevel: json['difficulty_level'] as int,
      autoDeleteAt: json['auto_delete_at'] != null
          ? DateTime.parse(json['auto_delete_at'] as String)
          : null,
      isUnlocked: json['is_unlocked'] as bool? ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'creator_id': creatorId,
      'content_encrypted': contentEncrypted,
      'unlock_method': unlockMethod,
      'judge_persona': judgePersona,
      'difficulty_level': difficultyLevel,
      'auto_delete_at': autoDeleteAt?.toIso8601String(),
      'is_unlocked': isUnlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
