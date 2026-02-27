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
    this.surpriseType = 'text',
    this.contentStoragePath,
    this.battleStatus = 'active',
    this.resolvedAt,
    this.archivedFlag = false,
    this.seekerScore = 0,
    this.resistanceScore,
    this.fatigueLevel = 0,
    this.lastActivityAt,
    this.winner,
    this.creatorDefenseCount = 0,
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
  final String surpriseType;
  final String? contentStoragePath;
  /// active = battle in progress; resolved = ended
  final String battleStatus;
  /// When battle_status was set to resolved (null while active).
  final DateTime? resolvedAt;
  final bool archivedFlag;
  final int seekerScore;
  final int? resistanceScore;
  final int fatigueLevel;
  final DateTime? lastActivityAt;
  final String? winner;
  final int creatorDefenseCount;

  bool get isPhoto => surpriseType == 'photo';
  bool get isVoice => surpriseType == 'voice';

  factory Surprise.fromJson(Map<String, dynamic> json) {
    return Surprise(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      creatorId: json['creator_id'] as String,
      contentEncrypted: (json['content_encrypted'] as String?) ?? '',
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
      surpriseType: (json['surprise_type'] as String?) ?? 'text',
      contentStoragePath: json['content_storage_path'] as String?,
      battleStatus: (json['battle_status'] as String?) ?? 'active',
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      archivedFlag: json['archived_flag'] as bool? ?? false,
      seekerScore: json['seeker_score'] as int? ?? 0,
      resistanceScore: json['resistance_score'] as int?,
      fatigueLevel: json['fatigue_level'] as int? ?? 0,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : null,
      winner: json['winner'] as String?,
      creatorDefenseCount: json['creator_defense_count'] as int? ?? 0,
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
      'surprise_type': surpriseType,
      'content_storage_path': contentStoragePath,
      'battle_status': battleStatus,
      'resolved_at': resolvedAt?.toIso8601String(),
      'archived_flag': archivedFlag,
      'seeker_score': seekerScore,
      'resistance_score': resistanceScore,
      'fatigue_level': fatigueLevel,
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'winner': winner,
      'creator_defense_count': creatorDefenseCount,
    };
  }
}
