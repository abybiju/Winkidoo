class DailyDare {
  const DailyDare({
    required this.id,
    required this.coupleId,
    required this.dareDate,
    required this.judgePersona,
    required this.dareText,
    required this.dareCategory,
    this.userAResponseEncrypted,
    this.userAResponseType = 'text',
    this.userASubmittedAt,
    this.userBResponseEncrypted,
    this.userBResponseType = 'text',
    this.userBSubmittedAt,
    this.gradeCommentary,
    this.gradeScore,
    this.gradeEmoji,
    this.gradeRoast,
    this.gradedAt,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String coupleId;
  final String dareDate;
  final String judgePersona;
  final String dareText;
  final String dareCategory;

  final String? userAResponseEncrypted;
  final String userAResponseType;
  final DateTime? userASubmittedAt;

  final String? userBResponseEncrypted;
  final String userBResponseType;
  final DateTime? userBSubmittedAt;

  final String? gradeCommentary;
  final int? gradeScore;
  final String? gradeEmoji;
  final String? gradeRoast;
  final DateTime? gradedAt;

  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;

  bool get isGraded => status == 'graded';
  bool get isExpired =>
      status == 'expired' || DateTime.now().isAfter(expiresAt);
  bool get bothSubmitted =>
      userASubmittedAt != null && userBSubmittedAt != null;

  /// Whether the current user has submitted their response.
  bool myResponseSubmitted(String userId, String userAId) {
    if (userId == userAId) return userASubmittedAt != null;
    return userBSubmittedAt != null;
  }

  /// Whether the partner has submitted their response.
  bool partnerResponseSubmitted(String userId, String userAId) {
    if (userId == userAId) return userBSubmittedAt != null;
    return userASubmittedAt != null;
  }

  factory DailyDare.fromJson(Map<String, dynamic> json) {
    return DailyDare(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      dareDate: json['dare_date'] as String,
      judgePersona: json['judge_persona'] as String,
      dareText: json['dare_text'] as String,
      dareCategory: (json['dare_category'] as String?) ?? 'playful',
      userAResponseEncrypted:
          json['user_a_response_encrypted'] as String?,
      userAResponseType:
          (json['user_a_response_type'] as String?) ?? 'text',
      userASubmittedAt: json['user_a_submitted_at'] != null
          ? DateTime.parse(json['user_a_submitted_at'] as String)
          : null,
      userBResponseEncrypted:
          json['user_b_response_encrypted'] as String?,
      userBResponseType:
          (json['user_b_response_type'] as String?) ?? 'text',
      userBSubmittedAt: json['user_b_submitted_at'] != null
          ? DateTime.parse(json['user_b_submitted_at'] as String)
          : null,
      gradeCommentary: json['grade_commentary'] as String?,
      gradeScore: json['grade_score'] as int?,
      gradeEmoji: json['grade_emoji'] as String?,
      gradeRoast: json['grade_roast'] as String?,
      gradedAt: json['graded_at'] != null
          ? DateTime.parse(json['graded_at'] as String)
          : null,
      status: (json['status'] as String?) ?? 'pending',
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'dare_date': dareDate,
      'judge_persona': judgePersona,
      'dare_text': dareText,
      'dare_category': dareCategory,
      'user_a_response_encrypted': userAResponseEncrypted,
      'user_a_response_type': userAResponseType,
      'user_a_submitted_at': userASubmittedAt?.toIso8601String(),
      'user_b_response_encrypted': userBResponseEncrypted,
      'user_b_response_type': userBResponseType,
      'user_b_submitted_at': userBSubmittedAt?.toIso8601String(),
      'grade_commentary': gradeCommentary,
      'grade_score': gradeScore,
      'grade_emoji': gradeEmoji,
      'grade_roast': gradeRoast,
      'graded_at': gradedAt?.toIso8601String(),
      'status': status,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
