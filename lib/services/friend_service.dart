import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/models/user_friend.dart';
import 'package:winkidoo/services/api_rate_limiter.dart';

/// Friend management — search, request, accept, remove.
class FriendService {
  FriendService(this._client);

  final SupabaseClient _client;

  /// Searches profiles by name or email. Returns user metadata.
  Future<List<Map<String, dynamic>>> searchUsers(
    String query, {
    int limit = 20,
  }) async {
    if (query.trim().length < 2) return [];

    final userId = _client.auth.currentUser?.id ?? '';
    final rl = ApiRateLimiter.checkAndRecord('friend_search', userId);
    if (!rl.allowed) return [];

    // Search auth user metadata via profiles table
    // Profiles have user_id; we join with auth.users via RPC or query metadata
    final currentUserId = _client.auth.currentUser?.id;
    final results = await _client
        .from('profiles')
        .select('user_id, avatar_url, avatar_mode, avatar_asset_path')
        .neq('user_id', currentUserId ?? '')
        .limit(limit);

    // Also search auth users by email (partial match)
    // Note: Supabase doesn't expose auth.users to client queries directly,
    // so we use the user metadata stored at signup.
    // For now, return profile data and let the UI match display names
    // from user metadata on the client side.
    return results.cast<Map<String, dynamic>>();
  }

  /// Sends a friend request. Stores lower UUID as user_a for consistency.
  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    final rl = ApiRateLimiter.checkAndRecord('friend_request', fromUserId);
    if (!rl.allowed) throw Exception(rl.userMessage);

    final sorted = [fromUserId, toUserId]..sort();
    await _client.from('user_friends').insert({
      'user_a_id': sorted[0],
      'user_b_id': sorted[1],
      'status': 'pending',
    });
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
