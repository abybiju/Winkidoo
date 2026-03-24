import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/xp_service.dart';

class CoupleXpData {
  final int totalXp;
  final int currentLevel;
  final double progress; // 0.0–1.0 within current level
  final int xpToNext;

  const CoupleXpData({
    required this.totalXp,
    required this.currentLevel,
    required this.progress,
    required this.xpToNext,
  });
}

final coupleXpProvider = FutureProvider<CoupleXpData?>((ref) async {
  final couple = ref.watch(coupleProvider).value;
  if (couple == null) return null;

  final client = ref.read(supabaseClientProvider);
  final row = await client
      .from('couple_xp')
      .select('total_xp, current_level')
      .eq('couple_id', couple.id)
      .maybeSingle();

  if (row == null) {
    return const CoupleXpData(
      totalXp: 0,
      currentLevel: 1,
      progress: 0,
      xpToNext: 50,
    );
  }

  final totalXp = (row['total_xp'] as int?) ?? 0;
  final level = XpService.levelForXp(totalXp);
  return CoupleXpData(
    totalXp: totalXp,
    currentLevel: level,
    progress: XpService.levelProgress(totalXp),
    xpToNext: XpService.xpToNextLevel(level),
  );
});
