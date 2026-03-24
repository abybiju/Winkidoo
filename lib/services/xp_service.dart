import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages couple XP and Love Level progression.
/// Level formula: level = floor(sqrt(totalXp / 50)) + 1
/// Level 1 = 0 XP, Level 2 = 50, Level 3 = 200, Level 4 = 450, Level 5 = 800...
class XpService {
  static int levelForXp(int totalXp) {
    if (totalXp <= 0) return 1;
    return sqrt(totalXp / 50).floor() + 1;
  }

  /// XP needed to reach [level] from scratch.
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return ((level - 1) * (level - 1) * 50);
  }

  /// XP needed to reach the NEXT level from [currentLevel].
  static int xpToNextLevel(int currentLevel) {
    return xpForLevel(currentLevel + 1) - xpForLevel(currentLevel);
  }

  /// Progress within the current level (0.0–1.0).
  static double levelProgress(int totalXp) {
    final level = levelForXp(totalXp);
    final start = xpForLevel(level);
    final end = xpForLevel(level + 1);
    if (end == start) return 1.0;
    return ((totalXp - start) / (end - start)).clamp(0.0, 1.0);
  }

  /// Awards [xpAmount] XP to the couple. Upserts the couple_xp row.
  /// Non-critical: errors are caught and swallowed so they don't break the main flow.
  static Future<void> awardXp(
    SupabaseClient client,
    String coupleId,
    int xpAmount,
  ) async {
    try {
      // Fetch current XP
      final row = await client
          .from('couple_xp')
          .select('total_xp')
          .eq('couple_id', coupleId)
          .maybeSingle();

      final currentXp = (row?['total_xp'] as int?) ?? 0;
      final newXp = currentXp + xpAmount;
      final newLevel = levelForXp(newXp);

      await client.from('couple_xp').upsert({
        'couple_id': coupleId,
        'total_xp': newXp,
        'current_level': newLevel,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Non-critical — never let XP errors break the main game flow
    }
  }
}
