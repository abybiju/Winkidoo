/// A single message in a character chat room.
///
/// `messageType` distinguishes human messages ('user') from Scene Party bot
/// rows ('director', 'castmate', 'game_card', 'system') which have a NULL
/// sender and are inserted only by the scene-director Edge Function.
class CharacterChatMessage {
  const CharacterChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.originalContent,
    this.transformedContent,
    required this.characterId,
    required this.characterName,
    this.toneId,
    this.isTransforming = false,
    this.messageType = 'user',
    this.payload,
    required this.createdAt,
  });

  final String id;
  final String roomId;

  /// Null for bot messages (director/castmate/game_card/system).
  final String? senderId;
  final String originalContent;
  final String? transformedContent;
  final String characterId;
  final String characterName;
  final String? toneId;
  final bool isTransforming;
  final String messageType;

  /// Structured extras for bot messages (e.g. game_id on a game card,
  /// best-performance data on a director verdict).
  final Map<String, dynamic>? payload;
  final DateTime createdAt;

  /// Shows transformed text if available, otherwise original.
  String get displayContent => transformedContent ?? originalContent;

  bool get isNormal => characterId == 'normal';

  bool get hasTone => toneId != null && toneId != 'none';

  bool get isUserMessage => messageType == 'user';
  bool get isDirector => messageType == 'director';
  bool get isCastmate => messageType == 'castmate';
  bool get isGameCard => messageType == 'game_card';
  bool get isSystem => messageType == 'system';

  factory CharacterChatMessage.fromJson(Map<String, dynamic> json) {
    return CharacterChatMessage(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      senderId: json['sender_id'] as String?,
      originalContent: json['original_content'] as String,
      transformedContent: json['transformed_content'] as String?,
      characterId: json['character_id'] as String? ?? 'normal',
      characterName: json['character_name'] as String? ?? 'Normal',
      toneId: json['tone_id'] as String?,
      isTransforming: json['is_transforming'] as bool? ?? false,
      messageType: json['message_type'] as String? ?? 'user',
      payload: json['payload'] as Map<String, dynamic>?,
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
      'tone_id': toneId,
      'is_transforming': isTransforming,
      'message_type': messageType,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
