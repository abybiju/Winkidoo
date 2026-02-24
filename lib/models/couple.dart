class Couple {
  const Couple({
    required this.id,
    required this.userAId,
    this.userBId,
    required this.inviteCode,
    this.linkedAt,
    required this.createdAt,
  });

  final String id;
  final String userAId;
  final String? userBId;
  final String inviteCode;
  final DateTime? linkedAt;
  final DateTime createdAt;

  bool get isLinked => userBId != null && userBId!.isNotEmpty;

  factory Couple.fromJson(Map<String, dynamic> json) {
    return Couple(
      id: json['id'] as String,
      userAId: json['user_a_id'] as String,
      userBId: json['user_b_id'] as String?,
      inviteCode: json['invite_code'] as String,
      linkedAt: json['linked_at'] != null
          ? DateTime.parse(json['linked_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_a_id': userAId,
      'user_b_id': userBId,
      'invite_code': inviteCode,
      'linked_at': linkedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
