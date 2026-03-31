/// A character chat room (couple, friend 1-on-1, or group).
class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.type,
    this.name,
    this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    this.members = const [],
    this.lastMessage,
    this.lastMessageAt,
  });

  final String id;
  final String type; // 'couple', 'friend', 'group'
  final String? name;
  final String? inviteCode;
  final String createdBy;
  final DateTime createdAt;
  final List<ChatRoomMember> members;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  bool get isGroup => type == 'group';
  bool get isCouple => type == 'couple';

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'friend',
      name: json['name'] as String?,
      inviteCode: json['invite_code'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  ChatRoom copyWith({
    List<ChatRoomMember>? members,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) {
    return ChatRoom(
      id: id,
      type: type,
      name: name,
      inviteCode: inviteCode,
      createdBy: createdBy,
      createdAt: createdAt,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}

/// A member of a chat room.
class ChatRoomMember {
  const ChatRoomMember({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.email,
  });

  final String id;
  final String roomId;
  final String userId;
  final String role; // 'admin', 'member'
  final DateTime joinedAt;
  final String? displayName;
  final String? email;

  bool get isAdmin => role == 'admin';

  factory ChatRoomMember.fromJson(Map<String, dynamic> json) {
    return ChatRoomMember(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}
