import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/models/character_chat_message.dart';
import 'package:winkidoo/models/character_preset.dart';
import 'package:winkidoo/models/chat_room.dart';

/// DB operations for character chat rooms and messages.
class CharacterChatService {
  CharacterChatService(this._client);

  final SupabaseClient _client;

  // ── Built-in character presets ──

  static const builtInPresets = <CharacterPreset>[
    CharacterPreset(
      id: 'normal',
      name: 'Normal',
      emoji: '',
      systemPrompt: '',
    ),
    CharacterPreset(
      id: 'trump',
      name: 'Trump',
      emoji: '\u{1F1FA}\u{1F1F8}',
      systemPrompt:
          'Speak like Donald Trump. Use superlatives constantly — "tremendous", '
          '"the best", "nobody does it better", "believe me". Use ALL CAPS for '
          'emphasis. Be self-aggrandizing and confident. Reference "winning" and '
          '"deals". Use short punchy sentences. Add "Sad!" or "Huge!" as punctuation.',
    ),
    CharacterPreset(
      id: 'shakespeare',
      name: 'Shakespeare',
      emoji: '\u{1F3AD}',
      systemPrompt:
          'Speak like William Shakespeare. Use Elizabethan English — "thy", "thou", '
          '"doth", "forsooth", "hark", "prithee". Add poetic flourishes and metaphors. '
          'Reference love, fate, and the stars. Use iambic rhythm where natural. '
          'Occasionally quote or parody famous Shakespeare lines.',
    ),
    CharacterPreset(
      id: 'pirate',
      name: 'Pirate',
      emoji: '\u{1F3F4}\u{200D}\u{2620}\u{FE0F}',
      systemPrompt:
          'Speak like a swashbuckling pirate captain. Use "Arrr", "ye", "matey", '
          '"scallywag", "shiver me timbers". Replace common words with nautical '
          'equivalents — "voyage" for "trip", "treasure" for "food", "crew" for '
          '"friends". Be boisterous and dramatic.',
    ),
    CharacterPreset(
      id: 'valley_girl',
      name: 'Valley Girl',
      emoji: '\u{1F485}',
      systemPrompt:
          'Speak like a stereotypical Valley Girl. Use "like", "totally", "omg", '
          '"I literally can\'t even", "sooo", "for real". Add vocal fry cues and '
          'uptalk (sentences that sound like questions?). Be enthusiastic and '
          'dramatic about everything. Use modern slang.',
    ),
    CharacterPreset(
      id: 'corporate',
      name: 'Corporate',
      emoji: '\u{1F4BC}',
      systemPrompt:
          'Speak in exaggerated corporate jargon. Use "per my last message", '
          '"circling back", "synergy", "let\'s take this offline", "moving the '
          'needle", "bandwidth". Sign off with "Best regards" or "Thanks in advance". '
          'Be passive-aggressive yet professional. Add "action items" and "KPIs".',
    ),
    CharacterPreset(
      id: 'yoda',
      name: 'Yoda',
      emoji: '\u{1F7E2}',
      systemPrompt:
          'Speak like Yoda from Star Wars. Invert sentence structure — put the '
          'object or verb before the subject. Add wisdom and philosophical musings. '
          'Use "Hmm, yes", "Strong with the Force, you are". Be cryptic yet wise. '
          'Keep sentences short and contemplative.',
    ),
    CharacterPreset(
      id: 'gordon_ramsay',
      name: 'Gordon Ramsay',
      emoji: '\u{1F468}\u{200D}\u{1F373}',
      systemPrompt:
          'Speak like Gordon Ramsay. Be passionate and dramatic. Use food metaphors '
          'for everything. Alternate between furious criticism and warm encouragement. '
          'Say "This is RAW!", "Finally, some good [thing]!", "IT\'S BEAUTIFUL!". '
          'Call people "donkey" affectionately. Be intense but ultimately caring.',
    ),
  ];

  // ── Room operations ──

  /// Creates a new chat room and adds members. Returns the room ID.
  Future<String> createRoom({
    required String type,
    String? name,
    required List<String> memberIds,
    required String createdBy,
  }) async {
    final roomResult = await _client
        .from('character_chat_rooms')
        .insert({
          'type': type,
          'name': name,
          'created_by': createdBy,
        })
        .select('id, invite_code')
        .single();

    final roomId = roomResult['id'] as String;

    // Add creator as admin
    final membersToInsert = <Map<String, dynamic>>[
      {'room_id': roomId, 'user_id': createdBy, 'role': 'admin'},
    ];

    // Add other members
    for (final memberId in memberIds) {
      if (memberId != createdBy) {
        membersToInsert.add({
          'room_id': roomId,
          'user_id': memberId,
          'role': 'member',
        });
      }
    }

    await _client.from('character_chat_members').insert(membersToInsert);
    return roomId;
  }

  /// Joins a room via invite code using RPC (bypasses RLS for lookup).
  /// Returns the room ID or null if code is invalid.
  Future<String?> joinRoomByCode(String inviteCode, String userId) async {
    final result = await _client.rpc(
      'join_chat_room_by_code',
      params: {'p_invite_code': inviteCode},
    );

    if (result == null) return null;
    return result as String;
  }

  /// Fetches all chat rooms the user is a member of, ordered by most recent activity.
  Future<List<ChatRoom>> fetchRooms(String userId) async {
    final memberRows = await _client
        .from('character_chat_members')
        .select('room_id')
        .eq('user_id', userId);

    if (memberRows.isEmpty) return [];

    final roomIds = memberRows.map((r) => r['room_id'] as String).toList();

    final rooms = await _client
        .from('character_chat_rooms')
        .select()
        .inFilter('id', roomIds)
        .order('created_at', ascending: false);

    return rooms.map((r) => ChatRoom.fromJson(r)).toList();
  }

  /// Fetches members of a room via RPC (bypasses RLS to see all members).
  Future<List<ChatRoomMember>> fetchMembers(String roomId) async {
    final rows = await _client.rpc(
      'get_chat_room_members',
      params: {'p_room_id': roomId},
    ) as List;

    return rows
        .map((r) => ChatRoomMember.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  // ── Message operations ──

  /// Fetches messages for a room, ordered by created_at ascending (oldest first).
  Future<List<CharacterChatMessage>> fetchMessages(
    String roomId, {
    int limit = 50,
  }) async {
    final rows = await _client
        .from('character_chat_messages')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .limit(limit);

    return rows.map((r) => CharacterChatMessage.fromJson(r)).toList();
  }

  /// Inserts a message (optimistic — may have is_transforming = true).
  Future<String> insertMessage({
    required String roomId,
    required String senderId,
    required String originalContent,
    required String characterId,
    required String characterName,
    bool isTransforming = false,
  }) async {
    final result = await _client
        .from('character_chat_messages')
        .insert({
          'room_id': roomId,
          'sender_id': senderId,
          'original_content': originalContent,
          'character_id': characterId,
          'character_name': characterName,
          'is_transforming': isTransforming,
        })
        .select('id')
        .single();

    return result['id'] as String;
  }

  /// Updates a message with the Gemini-transformed content.
  Future<void> updateTransformedContent(
    String messageId,
    String transformedContent,
  ) async {
    await _client.from('character_chat_messages').update({
      'transformed_content': transformedContent,
      'is_transforming': false,
    }).eq('id', messageId);
  }

  /// Marks a failed transform — falls back to original text.
  Future<void> markTransformFailed(String messageId) async {
    await _client.from('character_chat_messages').update({
      'is_transforming': false,
    }).eq('id', messageId);
  }

  // ── Room management ──

  Future<void> addMember(String roomId, String userId) async {
    await _client.from('character_chat_members').insert({
      'room_id': roomId,
      'user_id': userId,
      'role': 'member',
    });
  }

  /// Removes a member from a room (admin action via RPC).
  Future<void> removeMember(String roomId, String userId) async {
    await _client.rpc(
      'remove_chat_room_member',
      params: {'p_room_id': roomId, 'p_target_user_id': userId},
    );
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    await removeMember(roomId, userId);
  }
}
