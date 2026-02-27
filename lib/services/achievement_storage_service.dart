import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local-only storage for which achievements the user has "seen" (celebration shown).
/// Uses shared_preferences; no database.
class AchievementStorageService {
  AchievementStorageService._();

  static const String _keySeenIds = 'achievement_seen_ids';

  /// Returns the set of achievement IDs the user has already seen (unlock celebration shown).
  static Future<Set<String>> getSeenAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keySeenIds);
    if (json == null) return {};
    final list = jsonDecode(json) as List<dynamic>?;
    if (list == null) return {};
    return list.map((e) => e.toString()).toSet();
  }

  /// Marks an achievement as seen so we do not show the celebration again.
  static Future<void> markAsSeen(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = await getSeenAchievements();
    seen.add(id);
    await prefs.setString(_keySeenIds, jsonEncode(seen.toList()));
  }
}
