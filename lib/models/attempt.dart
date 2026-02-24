class Attempt {
  const Attempt({
    required this.id,
    required this.surpriseId,
    required this.userId,
    required this.content,
    this.aiScore,
    this.aiCommentary,
    required this.createdAt,
  });

  final String id;
  final String surpriseId;
  final String userId;
  final String content;
  final int? aiScore;
  final String? aiCommentary;
  final DateTime createdAt;

  factory Attempt.fromJson(Map<String, dynamic> json) {
    return Attempt(
      id: json['id'] as String,
      surpriseId: json['surprise_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      aiScore: json['ai_score'] as int?,
      aiCommentary: json['ai_commentary'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surprise_id': surpriseId,
      'user_id': userId,
      'content': content,
      'ai_score': aiScore,
      'ai_commentary': aiCommentary,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
