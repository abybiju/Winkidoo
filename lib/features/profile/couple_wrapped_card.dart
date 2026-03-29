import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/home/home_screen.dart';
import 'package:winkidoo/providers/couple_stats_provider.dart';
import 'package:winkidoo/providers/streak_provider.dart';
import 'package:winkidoo/providers/xp_provider.dart';

/// A "Spotify Wrapped for couples" shareable relationship summary.
/// Shows stats in a beautiful card that can be screenshotted or shared.
class CoupleWrappedSheet extends ConsumerStatefulWidget {
  const CoupleWrappedSheet({super.key});

  @override
  ConsumerState<CoupleWrappedSheet> createState() => _CoupleWrappedSheetState();
}

class _CoupleWrappedSheetState extends ConsumerState<CoupleWrappedSheet> {
  final _cardKey = GlobalKey();

  Future<void> _share() async {
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes,
                mimeType: 'image/png', name: 'couple_wrapped.png')
          ],
          text: 'Our Winkidoo Wrapped! #CoupleWrapped #Winkidoo',
        ),
      );
    } catch (e) {
      debugPrint('Share wrapped error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(coupleStatsProvider);
    final streakAsync = ref.watch(streakProvider);
    final xpAsync = ref.watch(coupleXpProvider);
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? AppTheme.surface2
            : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // The card
              RepaintBoundary(
                key: _cardKey,
                child: _WrappedCard(
                  statsAsync: statsAsync,
                  streakAsync: streakAsync,
                  xpAsync: xpAsync,
                ),
              ),
              const SizedBox(height: 20),

              // Share CTA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: const LinearGradient(
                      colors: [AppTheme.ctaOrangeA, AppTheme.ctaOrangeB],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.ctaOuterGlow.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: MaterialButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _share();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.share_rounded,
                            color: Color(0xFF4A2800), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Share Our Wrapped',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4A2800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WrappedCard extends StatelessWidget {
  const _WrappedCard({
    required this.statsAsync,
    required this.streakAsync,
    required this.xpAsync,
  });

  final AsyncValue<CoupleStats> statsAsync;
  final AsyncValue<StreakStats> streakAsync;
  final AsyncValue<CoupleXpData?> xpAsync;

  @override
  Widget build(BuildContext context) {
    final stats = statsAsync.value;
    final streak = streakAsync.value;
    final xp = xpAsync.value;

    final totalBattles = stats?.totalBattles ?? 0;
    final unlockRate = stats?.unlockRate ?? 0;
    final avgPersuasion = stats?.avgPersuasion ?? 0;
    final toughestJudge = stats?.toughestJudgePersonaId ?? '';
    final currentStreak = streak?.currentStreak ?? 0;
    final level = xp?.currentLevel ?? 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1030), Color(0xFF0D0620)],
        ),
        border: Border.all(
          color: AppTheme.primaryOrange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Header
          Text(
            'COUPLE WRAPPED',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: AppTheme.primaryOrangeLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your love, by the numbers',
            style: GoogleFonts.caveat(
              fontSize: 20,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  value: '$totalBattles',
                  label: 'Battles',
                  icon: Icons.flash_on_rounded,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  value: '${unlockRate.toInt()}%',
                  label: 'Win Rate',
                  icon: Icons.emoji_events_rounded,
                  color: AppTheme.premiumAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  value: avgPersuasion.toInt().toString(),
                  label: 'Avg Score',
                  icon: Icons.trending_up_rounded,
                  color: AppTheme.secondaryViolet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  value: '$currentStreak',
                  label: 'Day Streak',
                  icon: Icons.local_fire_department_rounded,
                  color: AppTheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  value: 'Lv $level',
                  label: 'Love Level',
                  icon: Icons.favorite_rounded,
                  color: AppTheme.primaryPink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  value: toughestJudge.isNotEmpty
                      ? HomeScreen.personaDisplayName(toughestJudge)
                      : '—',
                  label: 'Toughest Judge',
                  icon: Icons.gavel_rounded,
                  color: AppTheme.textOrangeAccent,
                  smallValue: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Branding
          Text(
            'Winkidoo  •  Unlock the surprise',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.smallValue = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool smallValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: smallValue ? 14 : 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
