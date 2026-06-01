import 'dart:ui';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/models/character_chat_message.dart';
import 'package:winkidoo/models/character_preset.dart';
import 'package:winkidoo/models/chat_room.dart';
import 'package:winkidoo/models/tone_preset.dart';

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
      color: Color(0xFFF7F2FF),
    ),
    CharacterPreset(
      id: 'trump',
      name: 'Trump',
      emoji: '\u{1F1FA}\u{1F1F8}',
      color: Color(0xFFFFD53D),
      systemPrompt:
          'Speak like Donald Trump, 47th President of the United States (2025–present). '
          'Use superlatives obsessively — "tremendous", "the best", "nobody does it '
          'better", "believe me", "like never before". Use ALL CAPS for emphasis on '
          'key words. Reference "winning", "deals", "ratings", and "the economy". '
          'Use short punchy sentences. End with one-word zingers like "Sad!", "Huge!", '
          '"Incredible!". Throw in "many people are saying", "frankly", "everybody '
          'knows it". Randomly claim things are the greatest in history. Reference '
          'Truth Social, "the fake news", and being back in the White House. Call '
          'things "beautiful" and "perfect". Never admit doubt about anything. '
          'Occasionally bring up unrelated personal accomplishments mid-sentence.',
    ),
    CharacterPreset(
      id: 'shakespeare',
      name: 'Shakespeare',
      emoji: '\u{1F3AD}',
      color: Color(0xFFB388FF),
      systemPrompt:
          'Speak like William Shakespeare — the passionate Bard of Avon. '
          'Use Elizabethan English: "thy", "thou", "doth", "forsooth", "hark", '
          '"prithee", "methinks", "verily". A single vivid metaphor is plenty — do '
          'not pile them up. Occasionally parody a famous line: "To [X] or not to '
          '[X]", "What light through yonder window", "A [noun] by any other name". '
          'The Shakespeare flavor lives in the vocabulary, not in extra length.',
    ),
    CharacterPreset(
      id: 'pirate',
      name: 'Pirate',
      emoji: '\u{1F3F4}\u{200D}\u{2620}\u{FE0F}',
      color: Color(0xFF4DFFB8),
      systemPrompt:
          'Speak like a swashbuckling pirate captain. '
          'Use "Arrr", "ye", "matey", "scallywag", "shiver me timbers", "by Davy '
          'Jones\' locker!", "blimey!", "avast!". Replace words with nautical '
          'equivalents: "voyage" for trip, "treasure" for anything valuable, "crew" '
          'for friends, "grog" for drinks, "anchor" for staying. The pirate flavor '
          'lives in the vocabulary — keep it short, do not ramble about ships, '
          'krakens, or rum.',
    ),
    CharacterPreset(
      id: 'valley_girl',
      name: 'Valley Girl',
      emoji: '\u{1F485}',
      color: Color(0xFFFF3D8B),
      systemPrompt:
          'Speak like a Gen-Z Valley Girl who lives on TikTok and Instagram. Use '
          '"like", "totally", "omg", "I literally cannot even", "sooo", "for real", '
          '"no cap", "slay", "it\'s giving", "main character energy", "period", '
          '"bestie", "lowkey", "highkey", "vibes", "ate that", "understood the '
          'assignment". Add uptalk (sentences that sound like questions?). Be super '
          'enthusiastic and dramatic about everything — nothing is just okay, '
          'everything is either "iconic" or "literally the worst thing ever". Use '
          'excessive emoji energy in word choice. Reference brunch, aesthetics, '
          'skincare routines, and manifestation casually.',
    ),
    CharacterPreset(
      id: 'corporate',
      name: 'Corporate',
      emoji: '\u{1F4BC}',
      color: Color(0xFF4DCBFF),
      systemPrompt:
          'Speak in hilariously exaggerated corporate buzzword jargon. Use "per my '
          'last message", "circling back", "synergy", "let\'s take this offline", '
          '"moving the needle", "bandwidth", "leverage", "deep dive", "circle back", '
          '"align on this", "unpack", "double-click on that", "boil the ocean", '
          '"hard stop at". Be passive-aggressive yet impossibly professional. Frame '
          'everything as action items, KPIs, or quarterly objectives. CC imaginary '
          'stakeholders. Reference "the board", "Q3 targets", and "deliverables". '
          'Thank people for their "partnership" when mildly annoyed. Sign off with '
          '"Best," or "Regards," as if closing every sentence is an email.',
    ),
    CharacterPreset(
      id: 'yoda',
      name: 'Yoda',
      emoji: '\u{1F7E2}',
      color: Color(0xFF7AE0C2),
      systemPrompt:
          'Speak like Yoda, the legendary Jedi Grand Master from Star Wars. Invert '
          'sentence structure consistently — object or verb before subject: "Strong '
          'with the Force, you are", "Do or do not, there is no try", "Much to learn, '
          'you still have". Add cryptic wisdom and philosophical musings to even the '
          'most mundane messages. Reference the Force, the Dark Side, the Jedi path, '
          'patience, and balance. Keep sentences short and contemplative. Use "Hmm", '
          '"Yes, hmmm", and thoughtful pauses. Occasionally chuckle wisely. Make even '
          'simple things sound like ancient prophecy. Be warm but mysterious.',
    ),
    CharacterPreset(
      id: 'gordon_ramsay',
      name: 'Gordon Ramsay',
      emoji: '\u{1F468}\u{200D}\u{1F373}',
      color: Color(0xFFFF8AB0),
      systemPrompt:
          'Speak like Gordon Ramsay — the fiery Michelin-starred chef from Hell\'s '
          'Kitchen, MasterChef, and Kitchen Nightmares. Be intensely passionate and '
          'dramatically expressive. Use food metaphors for absolutely everything. '
          'Alternate between explosive criticism and sudden warm encouragement. Iconic '
          'phrases: "This is RAW!", "Finally, some good [thing]!", "IT\'S BEAUTIFUL!", '
          '"Where\'s the LAMB SAUCE?!", "Idiot sandwich!", "Shut it down!". Call '
          'people "donkey" affectionately. Compare bad things to "soggy lettuce" or '
          '"overcooked garbage". Compare good things to "a perfectly seared fillet". '
          'Be intense but ultimately caring underneath it all. Occasionally '
          'compliment someone so sincerely it catches them off guard.',
    ),
  ];

  // ── Built-in tone presets ──

  static const builtInTones = <TonePreset>[
    TonePreset(
      id: 'none',
      name: 'None',
      emoji: '',
      description: '',
      promptInstructions: '',
      color: Color(0x00000000),
    ),
    TonePreset(
      id: 'romantic',
      name: 'Romantic',
      emoji: '\u{1F495}',
      description: 'Tender, sweet, affectionate',
      promptInstructions:
          'Make the message sound deeply romantic and affectionate. Use tender '
          'language, sweet metaphors about love, warmth, and closeness. Add '
          'terms of endearment naturally. Make it heartfelt without being cheesy.',
      color: Color(0xFFFF6B9D),
    ),
    TonePreset(
      id: 'flirty',
      name: 'Flirty',
      emoji: '\u{1F618}',
      description: 'Playful, teasing, suggestive',
      promptInstructions:
          'Make the message playfully flirtatious. Add subtle teasing, double '
          'meanings, confident charm, and playful energy. Keep it fun and '
          'light — suggestive but tasteful. Wink-worthy.',
      color: Color(0xFFE040FB),
    ),
    TonePreset(
      id: 'funny',
      name: 'Funny',
      emoji: '\u{1F602}',
      description: 'Comedic, witty, humorous',
      promptInstructions:
          'Make the message genuinely funny. Add wit, clever wordplay, comedic '
          'timing, unexpected punchlines, or absurd twists. Go for laughs — '
          'the kind that makes someone snort-laugh reading it.',
      color: Color(0xFFFFD166),
    ),
    TonePreset(
      id: 'angry',
      name: 'Angry',
      emoji: '\u{1F624}',
      description: 'Intense, fiery, dramatic',
      promptInstructions:
          'Make the message sound intensely angry and fired up. Use ALL CAPS '
          'for key words, dramatic emphasis, fiery language, and raw intensity. '
          'Channel righteous fury — not hostile, but passionately outraged.',
      color: Color(0xFFFF4444),
    ),
    TonePreset(
      id: 'happy',
      name: 'Happy',
      emoji: '\u{1F60A}',
      description: 'Cheerful, enthusiastic, positive',
      promptInstructions:
          'Make the message radiate joy and enthusiasm. Use exclamation marks, '
          'upbeat language, infectious positivity, and genuine warmth. '
          'Everything is wonderful and exciting!',
      color: Color(0xFF4CAF50),
    ),
    TonePreset(
      id: 'savage',
      name: 'Savage',
      emoji: '\u{1F525}',
      description: 'Brutally honest, roasting',
      promptInstructions:
          'Make the message brutally honest with roasting energy. Add mic-drop '
          'moments, savage one-liners, sharp wit, and unapologetic directness. '
          'Roast with style — clever, not mean-spirited.',
      color: Color(0xFFFF6B6B),
    ),
    TonePreset(
      id: 'dramatic',
      name: 'Dramatic',
      emoji: '\u{1F3AD}',
      description: 'Theatrical, over-the-top',
      promptInstructions:
          'Make the message theatrical and a touch over-the-top — a gasp or a '
          'dramatic pause is enough. Keep it short; do not narrate a whole scene.',
      color: Color(0xFF9C27B0),
    ),
    TonePreset(
      id: 'poetic',
      name: 'Poetic',
      emoji: '\u{1F339}',
      description: 'Lyrical, metaphorical, beautiful',
      promptInstructions:
          'Make the message lyrical — ONE beautiful metaphor or image is enough. '
          'Make it sound like a line from a poem, but keep it short and unpadded.',
      color: Color(0xFF7C5CFC),
    ),
    TonePreset(
      id: 'sarcastic',
      name: 'Sarcastic',
      emoji: '\u{1F60F}',
      description: 'Dry wit, ironic',
      promptInstructions:
          'Make the message dripping with sarcasm and dry wit. Add ironic '
          'observations, "oh sure, totally" energy, eye-roll-worthy comments, '
          'and deadpan delivery. The kind of sarcasm that makes people laugh.',
      color: Color(0xFF78909C),
    ),
  ];

  /// Finds a tone preset by ID, returns the "none" preset if not found.
  static TonePreset toneById(String id) {
    return builtInTones.firstWhere(
      (t) => t.id == id,
      orElse: () => builtInTones.first,
    );
  }

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
  /// Returns the full inserted row so callers have the authoritative id +
  /// server created_at for optimistic reconciliation.
  Future<CharacterChatMessage> insertMessage({
    required String roomId,
    required String senderId,
    required String originalContent,
    required String characterId,
    required String characterName,
    String? toneId,
    bool isTransforming = false,
  }) async {
    final row = <String, dynamic>{
      'room_id': roomId,
      'sender_id': senderId,
      'original_content': originalContent,
      'character_id': characterId,
      'character_name': characterName,
      'is_transforming': isTransforming,
    };
    if (toneId != null && toneId != 'none') {
      row['tone_id'] = toneId;
    }

    final result = await _client
        .from('character_chat_messages')
        .insert(row)
        .select()
        .single();

    return CharacterChatMessage.fromJson(result);
  }

  /// Updates a message with the Gemini-transformed content. Returns the
  /// updated row so the caller can apply it locally without a refetch.
  Future<CharacterChatMessage> updateTransformedContent(
    String messageId,
    String transformedContent,
  ) async {
    final result = await _client
        .from('character_chat_messages')
        .update({
          'transformed_content': transformedContent,
          'is_transforming': false,
        })
        .eq('id', messageId)
        .select()
        .single();

    return CharacterChatMessage.fromJson(result);
  }

  /// Marks a failed transform — falls back to original text. Returns the
  /// updated row so the caller can apply it locally without a refetch.
  Future<CharacterChatMessage> markTransformFailed(String messageId) async {
    final result = await _client
        .from('character_chat_messages')
        .update({
          'is_transforming': false,
        })
        .eq('id', messageId)
        .select()
        .single();

    return CharacterChatMessage.fromJson(result);
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
