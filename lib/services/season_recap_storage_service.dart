import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local-only storage for which season recaps the user has seen.
/// Uses shared_preferences; no database.
class SeasonRecapStorageService {
  SeasonRecapStorageService._();

  static const String _keySeenIds = 'season_recap_seen_ids';

  /// Returns true if the user has already seen the recap for this season.
  static Future<bool> hasSeenSeason(String seasonId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keySeenIds);
    if (json == null) return false;
    final list = jsonDecode(json) as List<dynamic>?;
    if (list == null) return false;
    return list.any((e) => e.toString() == seasonId);
  }

  /// Marks the season recap as seen so we do not show it again.
  static Future<void> markSeasonSeen(String seasonId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keySeenIds);
    final list = json != null ? (jsonDecode(json) as List<dynamic>? ?? <dynamic>[]) : <dynamic>[];
    final seen = list.map((e) => e.toString()).toSet();
    seen.add(seasonId);
    await prefs.setString(_keySeenIds, jsonEncode(seen.toList()));
  }
}
