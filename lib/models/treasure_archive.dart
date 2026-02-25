/// Metadata for a battle kept in Treasure (Keep in Treasure flow).
class TreasureArchive {
  const TreasureArchive({
    required this.id,
    required this.surpriseId,
    required this.coupleId,
    required this.judgePersona,
    required this.attemptsCount,
    required this.creatorInterventionsCount,
    this.winner,
    this.finalQuote,
    required this.archivedAt,
    this.contentReopenAllowed = true,
  });

  final String id;
  final String surpriseId;
  final String coupleId;
  final String judgePersona;
  final int attemptsCount;
  final int creatorInterventionsCount;
  final String? winner;
  final String? finalQuote;
  final DateTime archivedAt;
  final bool contentReopenAllowed;

  factory TreasureArchive.fromJson(Map<String, dynamic> json) {
    return TreasureArchive(
      id: json['id'] as String,
      surpriseId: json['surprise_id'] as String,
      coupleId: json['couple_id'] as String,
      judgePersona: json['judge_persona'] as String,
      attemptsCount: json['attempts_count'] as int? ?? 0,
      creatorInterventionsCount:
          json['creator_interventions_count'] as int? ?? 0,
      winner: json['winner'] as String?,
      finalQuote: json['final_quote'] as String?,
      archivedAt: DateTime.parse(json['archived_at'] as String),
      contentReopenAllowed: json['content_reopen_allowed'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surprise_id': surpriseId,
      'couple_id': coupleId,
      'judge_persona': judgePersona,
      'attempts_count': attemptsCount,
      'creator_interventions_count': creatorInterventionsCount,
      'winner': winner,
      'final_quote': finalQuote,
      'archived_at': archivedAt.toUtc().toIso8601String(),
      'content_reopen_allowed': contentReopenAllowed,
    };
  }
}
