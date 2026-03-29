import 'dart:convert';

class MiniGame {
  const MiniGame({
    required this.id,
    required this.coupleId,
    required this.gameDate,
    required this.gameType,
    required this.judgePersona,
    this.packId,
    required this.gamePrompt,
    this.gameOptions,
    this.userAResponse,
    this.userASubmittedAt,
    this.userBResponse,
    this.userBSubmittedAt,
    this.gradeCommentary,
    this.gradeScore,
    this.gradeEmoji,
    this.gradedAt,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String coupleId;
  final String gameDate;
  final String gameType;
  final String judgePersona;
  final String? packId;
  final String gamePrompt;
  final List<String>? gameOptions;

  final String? userAResponse;
  final DateTime? userASubmittedAt;
  final String? userBResponse;
  final DateTime? userBSubmittedAt;

  final String? gradeCommentary;
  final int? gradeScore;
  final String? gradeEmoji;
  final DateTime? gradedAt;

  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;

  bool get isGraded => status == 'graded';
  bool get isExpired =>
      status == 'expired' || DateTime.now().isAfter(expiresAt);
  bool get bothSubmitted =>
      userASubmittedAt != null && userBSubmittedAt != null;

  bool myResponseSubmitted(String userId, String userAId) {
    if (userId == userAId) return userASubmittedAt != null;
    return userBSubmittedAt != null;
  }

  bool partnerResponseSubmitted(String userId, String userAId) {
    if (userId == userAId) return userBSubmittedAt != null;
    return userASubmittedAt != null;
  }

  String get gameTypeDisplayName {
    switch (gameType) {
      case 'would_you_rather':
        return 'Would You Rather';
      case 'love_trivia':
        return 'Love Trivia';
      case 'caption_this':
        return 'Caption This';
      case 'finish_my_sentence':
        return 'Finish My Sentence';
      default:
        return gameType;
    }
  }

  factory MiniGame.fromJson(Map<String, dynamic> json) {
    List<String>? options;
    final rawOptions = json['game_options'];
    if (rawOptions is List) {
      options = rawOptions.cast<String>();
    } else if (rawOptions is String) {
      final decoded = jsonDecode(rawOptions);
      if (decoded is List) options = decoded.cast<String>();
    }

    return MiniGame(
      id: json['id'] as String,
      coupleId: json['couple_id'] as String,
      gameDate: json['game_date'] as String,
      gameType: json['game_type'] as String,
      judgePersona: json['judge_persona'] as String,
      packId: json['pack_id'] as String?,
      gamePrompt: json['game_prompt'] as String,
      gameOptions: options,
      userAResponse: json['user_a_response'] as String?,
      userASubmittedAt: json['user_a_submitted_at'] != null
          ? DateTime.parse(json['user_a_submitted_at'] as String)
          : null,
      userBResponse: json['user_b_response'] as String?,
      userBSubmittedAt: json['user_b_submitted_at'] != null
          ? DateTime.parse(json['user_b_submitted_at'] as String)
          : null,
      gradeCommentary: json['grade_commentary'] as String?,
      gradeScore: json['grade_score'] as int?,
      gradeEmoji: json['grade_emoji'] as String?,
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
      'game_date': gameDate,
      'game_type': gameType,
      'judge_persona': judgePersona,
      'pack_id': packId,
      'game_prompt': gamePrompt,
      'game_options': gameOptions,
      'user_a_response': userAResponse,
      'user_a_submitted_at': userASubmittedAt?.toIso8601String(),
      'user_b_response': userBResponse,
      'user_b_submitted_at': userBSubmittedAt?.toIso8601String(),
      'grade_commentary': gradeCommentary,
      'grade_score': gradeScore,
      'grade_emoji': gradeEmoji,
      'graded_at': gradedAt?.toIso8601String(),
      'status': status,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
