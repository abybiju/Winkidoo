/// A single message in a character chat room.
class CharacterChatMessage {
  const CharacterChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.originalContent,
    this.transformedContent,
    required this.characterId,
    required this.characterName,
    this.isTransforming = false,
    required this.createdAt,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String originalContent;
  final String? transformedContent;
  final String characterId;
  final String characterName;
  final bool isTransforming;
  final DateTime createdAt;

  /// Shows transformed text if available, otherwise original.
  String get displayContent => transformedContent ?? originalContent;

  bool get isNormal => characterId == 'normal';

  factory CharacterChatMessage.fromJson(Map<String, dynamic> json) {
    return CharacterChatMessage(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      senderId: json['sender_id'] as String,
      originalContent: json['original_content'] as String,
      transformedContent: json['transformed_content'] as String?,
      characterId: json['character_id'] as String? ?? 'normal',
      characterName: json['character_name'] as String? ?? 'Normal',
      isTransforming: json['is_transforming'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'original_content': originalContent,
      'transformed_content': transformedContent,
      'character_id': characterId,
      'character_name': characterName,
      'is_transforming': isTransforming,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
