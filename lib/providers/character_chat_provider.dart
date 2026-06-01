import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:winkidoo/models/character_chat_message.dart';
import 'package:winkidoo/models/character_preset.dart';
import 'package:winkidoo/models/chat_room.dart';
import 'package:winkidoo/models/user_friend.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
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
  try {
    final rooms = await service.fetchRooms(user.id);
    debugPrint('[ChatProvider] Loaded ${rooms.length} rooms for ${user.id}');
    return rooms;
  } catch (e, st) {
    debugPrint('[ChatProvider] fetchRooms error: $e');
    debugPrint('[ChatProvider] stackTrace: $st');
    rethrow;
  }
});

/// A single room by ID (from cached rooms list).
final chatRoomProvider =
    FutureProvider.family<ChatRoom?, String>((ref, roomId) async {
  final rooms = await ref.watch(myRoomsProvider.future);
  try {
    return rooms.firstWhere((r) => r.id == roomId);
  } catch (_) {
    return null;
  }
});

/// Members of a specific room.
final roomMembersProvider =
    FutureProvider.family<List<ChatRoomMember>, String>((ref, roomId) async {
  final service = ref.watch(characterChatServiceProvider);
  return service.fetchMembers(roomId);
});

// ── Message providers ──

/// Messages for a specific room. Realtime (postgres changes) and optimistic
/// sends push targeted upserts into this notifier instead of refetching the
/// whole list — so new messages apply instantly with no flicker.
final chatMessagesProvider = AsyncNotifierProvider.family<ChatMessagesNotifier,
    List<CharacterChatMessage>, String>(ChatMessagesNotifier.new);

class ChatMessagesNotifier
    extends AsyncNotifier<List<CharacterChatMessage>> {
  ChatMessagesNotifier(this.roomId);

  final String roomId;

  @override
  Future<List<CharacterChatMessage>> build() async {
    final service = ref.watch(characterChatServiceProvider);
    return service.fetchMessages(roomId);
  }

  /// Insert-or-replace by id, keeping the list sorted by createdAt ascending.
  void upsert(CharacterChatMessage msg) {
    final current = state.value ?? const <CharacterChatMessage>[];
    final next = [...current];
    final idx = next.indexWhere((m) => m.id == msg.id);
    if (idx >= 0) {
      next[idx] = msg;
    } else {
      next.add(msg);
    }
    next.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = AsyncData(next);
  }

  /// Removes a message by id (e.g. dropping a failed optimistic send).
  void remove(String id) {
    final current = state.value ?? const <CharacterChatMessage>[];
    state = AsyncData(current.where((m) => m.id != id).toList());
  }

  /// Replaces an optimistic temp message with the authoritative server row.
  void reconcile(String tempId, CharacterChatMessage real) {
    final current = state.value ?? const <CharacterChatMessage>[];
    final next = current.where((m) => m.id != tempId).toList()..add(real);
    next.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = AsyncData(next);
  }
}

// ── Character providers ──

/// Currently selected character ID for the chat input.
final selectedCharacterProvider = StateProvider<String>((ref) => 'normal');

/// Currently selected tone ID for the chat input.
final selectedToneProvider = StateProvider<String>((ref) => 'none');

/// All available characters: built-in presets + couple's custom judges.
final availableCharactersProvider =
    FutureProvider<List<CharacterPreset>>((ref) async {
  const builtIns = CharacterChatService.builtInPresets;

  // Also add custom judges if couple exists
  try {
    final client = ref.watch(supabaseClientProvider);
    final user = ref.watch(currentUserProvider);
    if (user == null) return builtIns;

    final couple = ref.watch(coupleProvider).value;
    final coupleId = couple?.id;

    // Fetch couple's own judges + published marketplace judges (chat-compatible only)
    var query = client
        .from('custom_judges')
        .select('id, personality_name, avatar_emoji, generated_persona_prompt, use_for')
        .inFilter('use_for', ['chat', 'both']);
    if (coupleId != null) {
      query = query.or('couple_id.eq.$coupleId,is_published.eq.true');
    } else {
      query = query.eq('is_published', true);
    }
    final judges = await query
        .order('created_at', ascending: false)
        .limit(20);

    final customPresets = (judges as List).map((j) {
      return CharacterPreset(
        id: j['id'] as String,
        name: j['personality_name'] as String? ?? 'Custom',
        emoji: j['avatar_emoji'] as String? ?? '\u{1F3AD}',
        systemPrompt: j['generated_persona_prompt'] as String? ?? '',
        isBuiltIn: false,
        color: const Color(0xFFB388FF),
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

/// All pending friend requests involving the current user (both directions).
final pendingFriendRequestsProvider =
    FutureProvider<List<UserFriend>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final service = ref.watch(friendServiceProvider);
  return service.fetchPendingRequests(user.id);
});

/// Pending requests the current user RECEIVED (can accept/decline).
final incomingFriendRequestsProvider =
    FutureProvider<List<UserFriend>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final pending = await ref.watch(pendingFriendRequestsProvider.future);
  return pending.where((f) => f.isIncomingFor(user.id)).toList();
});

/// display_name + avatar for every friend and pending-request counterparty,
/// keyed by user_id. Used to render names in the friends UI.
final friendDirectoryProvider =
    FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  final friends = await ref.watch(friendsListProvider.future);
  final pending = await ref.watch(pendingFriendRequestsProvider.future);
  final ids = <String>{
    ...friends.map((f) => f.friendId(user.id)),
    ...pending.map((f) => f.friendId(user.id)),
  }.toList();
  return ref.watch(friendServiceProvider).fetchProfiles(ids);
});
