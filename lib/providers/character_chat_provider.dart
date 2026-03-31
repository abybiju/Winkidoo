import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:winkidoo/models/character_chat_message.dart';
import 'package:winkidoo/models/character_preset.dart';
import 'package:winkidoo/models/chat_room.dart';
import 'package:winkidoo/models/user_friend.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/character_chat_service.dart';
import 'package:winkidoo/services/friend_service.dart';

// ── Service providers ──

final characterChatServiceProvider = Provider<CharacterChatService>((ref) {
  return CharacterChatService(ref.watch(supabaseClientProvider));
});

final friendServiceProvider = Provider<FriendService>((ref) {
  return FriendService(ref.watch(supabaseClientProvider));
});

// ── Room providers ──

/// All chat rooms for the current user.
final myRoomsProvider = FutureProvider<List<ChatRoom>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final service = ref.watch(characterChatServiceProvider);
  return service.fetchRooms(user.id);
});

/// Members of a specific room.
final roomMembersProvider =
    FutureProvider.family<List<ChatRoomMember>, String>((ref, roomId) async {
  final service = ref.watch(characterChatServiceProvider);
  return service.fetchMembers(roomId);
});

// ── Message providers ──

/// Messages for a specific room (invalidated by realtime callback).
final chatMessagesProvider =
    FutureProvider.family<List<CharacterChatMessage>, String>(
        (ref, roomId) async {
  final service = ref.watch(characterChatServiceProvider);
  return service.fetchMessages(roomId);
});

// ── Character providers ──

/// Currently selected character ID for the chat input.
final selectedCharacterProvider = StateProvider<String>((ref) => 'normal');

/// All available characters: built-in presets + couple's custom judges.
final availableCharactersProvider =
    FutureProvider<List<CharacterPreset>>((ref) async {
  const builtIns = CharacterChatService.builtInPresets;

  // Also add custom judges if couple exists
  try {
    final client = ref.watch(supabaseClientProvider);
    final user = ref.watch(currentUserProvider);
    if (user == null) return builtIns;

    final judges = await client
        .from('custom_judges')
        .select('id, personality_name, avatar_emoji, generated_persona_prompt')
        .order('created_at', ascending: false)
        .limit(20);

    final customPresets = (judges as List).map((j) {
      return CharacterPreset(
        id: j['id'] as String,
        name: j['personality_name'] as String? ?? 'Custom',
        emoji: j['avatar_emoji'] as String? ?? '\u{1F3AD}',
        systemPrompt: j['generated_persona_prompt'] as String? ?? '',
        isBuiltIn: false,
      );
    }).toList();

    return [...builtIns, ...customPresets];
  } catch (_) {
    return builtIns;
  }
});

// ── Friend providers ──

/// Accepted friends list.
final friendsListProvider = FutureProvider<List<UserFriend>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final service = ref.watch(friendServiceProvider);
  return service.fetchFriends(user.id);
});

/// Pending incoming friend requests.
final pendingFriendRequestsProvider =
    FutureProvider<List<UserFriend>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final service = ref.watch(friendServiceProvider);
  return service.fetchPendingRequests(user.id);
});
