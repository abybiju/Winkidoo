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
    this.questId,
    this.questStep,
    this.unlockAfter,
    this.isCollaborative = false,
    this.collabPartnerPieceEncrypted,
    this.collabPartnerStatus = 'pending',
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
  final String battleStatus;
  final DateTime? resolvedAt;
  final bool archivedFlag;
  final int seekerScore;
  final int? resistanceScore;
  final int fatigueLevel;
  final DateTime? lastActivityAt;
  final String? winner;
  final int creatorDefenseCount;
  final String? questId;
  final int? questStep;
  final DateTime? unlockAfter;

  /// Collaborative vault fields
  final bool isCollaborative;
  final String? collabPartnerPieceEncrypted;
  /// pending = partner hasn't added piece yet; added = ready for battle
  final String collabPartnerStatus;

  bool get isPhoto => surpriseType == 'photo';
  bool get isVoice => surpriseType == 'voice';
  bool get isQuestSurprise => questId != null;
  bool get isTimeLocked =>
      unlockAfter != null && unlockAfter!.isAfter(DateTime.now());
  bool get isAwaitingCollabPiece =>
      isCollaborative && collabPartnerStatus == 'pending';

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
      questId: json['quest_id'] as String?,
      questStep: json['quest_step'] as int?,
      unlockAfter: json['unlock_after'] != null
          ? DateTime.parse(json['unlock_after'] as String)
          : null,
      isCollaborative: json['is_collaborative'] as bool? ?? false,
      collabPartnerPieceEncrypted:
          json['collab_partner_piece_encrypted'] as String?,
      collabPartnerStatus:
          (json['collab_partner_status'] as String?) ?? 'pending',
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
      'quest_id': questId,
      'quest_step': questStep,
      'unlock_after': unlockAfter?.toIso8601String(),
      'is_collaborative': isCollaborative,
      'collab_partner_piece_encrypted': collabPartnerPieceEncrypted,
      'collab_partner_status': collabPartnerStatus,
    };
  }
}
