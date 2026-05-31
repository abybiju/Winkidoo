import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/models/user_friend.dart';
import 'package:winkidoo/services/api_rate_limiter.dart';
import 'package:winkidoo/services/input_validator.dart';

/// Friend management — search, request, accept, remove.
class FriendService {
  FriendService(this._client);

  final SupabaseClient _client;

  /// Searches users by display name via the `search_users_by_name` RPC.
  /// Returns rows: user_id, display_name, avatar_url, avatar_mode, avatar_asset_path.
  Future<List<Map<String, dynamic>>> searchUsers(
    String query, {
    int limit = 20,
  }) async {
    if (query.trim().length < 2) return [];
    query = InputValidator.sanitizeSearchQuery(query);

    final userId = _client.auth.currentUser?.id ?? '';
    final rl = ApiRateLimiter.checkAndRecord('friend_search', userId);
    if (!rl.allowed) return [];

    final results = await _client
        .rpc('search_users_by_name', params: {'p_query': query});
    return (results as List).cast<Map<String, dynamic>>();
  }

  /// Fetches display name + avatar for a set of user ids (for requests/friends UI).
  /// Returns a map keyed by user_id.
  Future<Map<String, Map<String, dynamic>>> fetchProfiles(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    final rows = await _client
        .from('profiles')
        .select('user_id, display_name, avatar_url, avatar_mode, avatar_asset_path')
        .inFilter('user_id', userIds);
    final map = <String, Map<String, dynamic>>{};
    for (final r in (rows as List).cast<Map<String, dynamic>>()) {
      map[r['user_id'] as String] = r;
    }
    return map;
  }

  /// Sends a friend request. Stores lower UUID as user_a for consistency.
  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    final rl = ApiRateLimiter.checkAndRecord('friend_request', fromUserId);
    if (!rl.allowed) throw Exception(rl.userMessage);

    final sorted = [fromUserId, toUserId]..sort();
    // upsert: if a friendship row already exists for this pair (either direction),
    // do nothing rather than throwing on the unique(user_a,user_b) constraint.
    await _client.from('user_friends').upsert({
      'user_a_id': sorted[0],
      'user_b_id': sorted[1],
      'status': 'pending',
      'requested_by': fromUserId,
    }, onConflict: 'user_a_id,user_b_id', ignoreDuplicates: true);
  }

  /// Accepts a pending friend request. Verifies caller is a party to it.
  Future<void> acceptFriendRequest(String friendshipId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    await _client
        .from('user_friends')
        .update({'status': 'accepted'})
        .eq('id', friendshipId)
        .or('user_a_id.eq.$userId,user_b_id.eq.$userId');
  }

  /// Removes a friendship. Verifies caller is a party to it.
  Future<void> removeFriend(String friendshipId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    await _client
        .from('user_friends')
        .delete()
        .eq('id', friendshipId)
        .or('user_a_id.eq.$userId,user_b_id.eq.$userId');
  }

  /// Fetches accepted friends for the current user.
  Future<List<UserFriend>> fetchFriends(String userId) async {
    final rows = await _client
        .from('user_friends')
        .select()
        .eq('status', 'accepted')
        .or('user_a_id.eq.$userId,user_b_id.eq.$userId')
        .order('created_at', ascending: false);

    return rows.map((r) => UserFriend.fromJson(r)).toList();
  }

  /// Fetches pending friend requests sent TO this user.
  Future<List<UserFriend>> fetchPendingRequests(String userId) async {
    final rows = await _client
        .from('user_friends')
        .select()
        .eq('status', 'pending')
        .or('user_a_id.eq.$userId,user_b_id.eq.$userId')
        .order('created_at', ascending: false);

    return rows.map((r) => UserFriend.fromJson(r)).toList();
  }
}
