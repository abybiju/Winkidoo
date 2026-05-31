/// A friendship between two users.
class UserFriend {
  const UserFriend({
    required this.id,
    required this.userAId,
    required this.userBId,
    required this.status,
    required this.createdAt,
    this.requestedBy,
    this.friendDisplayName,
    this.friendEmail,
  });

  final String id;
  final String userAId;
  final String userBId;
  final String status; // 'pending', 'accepted'
  final DateTime createdAt;
  /// Who sent the request (null for legacy rows). Used to tell incoming from outgoing.
  final String? requestedBy;
  final String? friendDisplayName;
  final String? friendEmail;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  /// Returns the other user's ID relative to [myUserId].
  String friendId(String myUserId) =>
      userAId == myUserId ? userBId : userAId;

  /// True when this is a pending request the given user RECEIVED (can accept).
  bool isIncomingFor(String myUserId) =>
      isPending && requestedBy != null && requestedBy != myUserId;

  factory UserFriend.fromJson(Map<String, dynamic> json) {
    return UserFriend(
      id: json['id'] as String,
      userAId: json['user_a_id'] as String,
      userBId: json['user_b_id'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      requestedBy: json['requested_by'] as String?,
    );
  }
}
