import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/battle_pass_provider.dart';

class BattlePassBar extends ConsumerWidget {
  const BattlePassBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final bpAsync = ref.watch(battlePassProvider);
    final bp = bpAsync.value;

    final points = bp?.points ?? 0;
    final seasonName = bp?.seasonName ?? 'Season 1';
    final tier = bp?.tier ?? 'bronze';
    final tierMax = _tierMax(tier);
    final progress = tierMax > 0 ? (points / tierMax).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => context.push('/shell/battle-pass'),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'BATTLE PASS · ${seasonName.toUpperCase()}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: brightness == Brightness.dark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$points',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ctaGoldA,
                      ),
                    ),
                    TextSpan(
                      text: ' / $tierMax',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: brightness == Brightness.dark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: brightness == Brightness.dark
                          ? AppTheme.glassFill
                          : AppTheme.lightGlassFill,
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.ctaGoldA, AppTheme.primaryOrange],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static int _tierMax(String tier) {
    switch (tier) {
      case 'gold':
        return 500;
      case 'silver':
        return 250;
      default:
        return 100;
    }
  }
}
