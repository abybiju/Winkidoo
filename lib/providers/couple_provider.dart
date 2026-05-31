import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/models/couple.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/subscription_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

class CoupleNotifier extends AsyncNotifier<Couple?> {
  @override
  Future<Couple?> build() async {
    try {
      final client = ref.watch(supabaseClientProvider);
      final user = ref.watch(currentUserProvider);
      if (user == null) return null;

      // Fetch ALL couple rows where this user is a member (handles duplicates)
      final rows = await client
          .from('couples')
          .select()
          .or('user_a_id.eq.${user.id},user_b_id.eq.${user.id}')
          .order('created_at', ascending: false);

      final list = rows is List ? rows : <dynamic>[];
      if (list.isEmpty) return null;

      // Prefer a linked couple (user_b_id is set) over an unlinked one
      Map<String, dynamic>? best;
      for (final row in list) {
        if (row is Map<String, dynamic>) {
          if (row['user_b_id'] != null) {
            best = row;
            break;
          }
          best ??= row;
        }
      }

      if (best != null) return Couple.fromJson(best);
      return null;
    } catch (e, st) {
      debugPrint('coupleProvider: $e');
      debugPrint('$st');
      return null;
    }
  }

  void setCouple(Couple c) {
    state = AsyncData(c);
  }
}

final coupleProvider =
    AsyncNotifierProvider<CoupleNotifier, Couple?>(() => CoupleNotifier());

/// All couple rows the current user belongs to — one per friend pair.
/// (A user can now be in many couples; [coupleProvider] is the legacy
/// single-value shim that returns the most recent linked pair.)
final couplesListProvider = FutureProvider<List<Couple>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final rows = await client
      .from('couples')
      .select()
      .or('user_a_id.eq.${user.id},user_b_id.eq.${user.id}')
      .order('created_at', ascending: false);
  return (rows as List)
      .whereType<Map<String, dynamic>>()
      .map(Couple.fromJson)
      .toList();
});

/// A friend pairing: the couple container + the OTHER member's profile.
class FriendPair {
  const FriendPair({
    required this.couple,
    required this.friendUserId,
    this.displayName,
    this.avatarUrl,
    this.avatarMode,
    this.avatarAssetPath,
  });

  final Couple couple;
  final String friendUserId;
  final String? displayName;
  final String? avatarUrl;
  final String? avatarMode;
  final String? avatarAssetPath;

  String get coupleId => couple.id;
  String get name =>
      (displayName != null && displayName!.trim().isNotEmpty)
          ? displayName!.trim()
          : 'Friend';
}

/// Linked friend pairs (both members present) with the friend's profile —
/// drives the Home avatar rail and the create-surprise friend picker.
final friendPairsProvider = FutureProvider<List<FriendPair>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final couples = await ref.watch(couplesListProvider.future);
  final linked = couples.where((c) => c.isLinked).toList();
  if (linked.isEmpty) return [];

  final friendIds = linked
      .map((c) => c.userAId == user.id ? c.userBId! : c.userAId)
      .toList();
  final profiles = await client
      .from('profiles')
      .select('user_id, display_name, avatar_url, avatar_mode, avatar_asset_path')
      .inFilter('user_id', friendIds);
  final pMap = <String, Map<String, dynamic>>{};
  for (final r in (profiles as List).cast<Map<String, dynamic>>()) {
    pMap[r['user_id'] as String] = r;
  }

  return linked.map((c) {
    final fid = c.userAId == user.id ? c.userBId! : c.userAId;
    final p = pMap[fid];
    return FriendPair(
      couple: c,
      friendUserId: fid,
      displayName: p?['display_name'] as String?,
      avatarUrl: p?['avatar_url'] as String?,
      avatarMode: p?['avatar_mode'] as String?,
      avatarAssetPath: p?['avatar_asset_path'] as String?,
    );
  }).toList();
});

/// Effective Wink+ status: true when couple has Wink+ (DB), RevenueCat entitlement is active,
/// or forceWinkPlusForTesting is on (debug).
final effectiveWinkPlusProvider = Provider<bool>((ref) {
  final couple = ref.watch(coupleProvider).value;
  final dbWinkPlus = couple?.isWinkPlus ?? false;

  // RevenueCat entitlement (real-time from SDK).
  final rcActive = ref.watch(rcEntitlementProvider).value ?? false;

  return dbWinkPlus || rcActive || AppConstants.forceWinkPlusForTesting;
});
