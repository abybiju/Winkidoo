/// A single message in a live judge battle chat.
class BattleMessage {
  const BattleMessage({
    required this.id,
    required this.surpriseId,
    required this.senderType,
    this.senderId,
    required this.content,
    this.isVerdict = false,
    this.verdictScore,
    this.verdictUnlocked,
    required this.createdAt,
  });

  final String id;
  final String surpriseId;
  final String senderType;
  final String? senderId;
  final String content;
  final bool isVerdict;
  final int? verdictScore;
  final bool? verdictUnlocked;
  final DateTime createdAt;

  bool get isFromSeeker => senderType == 'seeker';
  bool get isFromCreator => senderType == 'creator';
  bool get isFromJudge => senderType == 'judge';

  factory BattleMessage.fromJson(Map<String, dynamic> json) {
    return BattleMessage(
      id: json['id'] as String,
      surpriseId: json['surprise_id'] as String,
      senderType: json['sender_type'] as String,
      senderId: json['sender_id'] as String?,
      content: json['content'] as String,
      isVerdict: json['is_verdict'] as bool? ?? false,
      verdictScore: json['verdict_score'] as int?,
      verdictUnlocked: json['verdict_unlocked'] as bool?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surprise_id': surpriseId,
      'sender_type': senderType,
      'sender_id': senderId,
      'content': content,
      'is_verdict': isVerdict,
      'verdict_score': verdictScore,
      'verdict_unlocked': verdictUnlocked,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
