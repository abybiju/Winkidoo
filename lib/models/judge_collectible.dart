class JudgeCollectible {
  const JudgeCollectible({
    required this.id,
    required this.coupleId,
    required this.judgePersona,
    required this.rarity,
    this.battleId,
    this.seekerScore,
    required this.earnedAt,
  });

  final String id;
  final String coupleId;
  final String judgePersona;
  final String rarity; // 'common' | 'rare' | 'legendary'
  final String? battleId;
  final int? seekerScore;
  final DateTime earnedAt;

  factory JudgeCollectible.fromJson(Map<String, dynamic> json) {
    return JudgeCollectible(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      judgePersona: json['judge_persona'] as String,
      rarity: (json['rarity'] as String?) ?? 'common',
      battleId: json['battle_id'] as String?,
      seekerScore: json['seeker_score'] as int?,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }
}
