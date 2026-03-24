import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/winkidoo_top_bar.dart';
import 'package:winkidoo/providers/winks_provider.dart';

class WinksTabScreen extends ConsumerWidget {
  const WinksTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final winks = ref.watch(winksBalanceProvider).value;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppTheme.homeBackgroundGradient(brightness),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.25),
                    radius: 1.1,
                    colors: [
                      AppTheme.homeGlowPink.withValues(alpha: 0.06),
                      AppTheme.homeGlowOrange.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const WinkidooTopBar(
                    matchLogoToWordmark: true,
                    showLogo: true,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLarge),
                      color: brightness == Brightness.dark
                          ? AppTheme.glassFill
                          : Colors.white.withValues(alpha: 0.70),
                      border: Border.all(
                        color: brightness == Brightness.dark
                            ? AppTheme.glassBorder
                            : AppTheme.lightGlassBorder,
                      ),
                      boxShadow: AppTheme.elevation2(brightness),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFE37B),
                                Color(0xFFF5C76B),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.premiumGold
                                    .withValues(alpha: 0.30),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_emotions_rounded,
                            size: 28,
                            color: Color(0xFF6E4500),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${winks?.balance ?? 0}',
                          style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: brightness == Brightness.dark
                                ? AppTheme.homeTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'Winks',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: brightness == Brightness.dark
                                ? AppTheme.homeTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Use Winks for hints, persuasion boosts,\nand instant unlock.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            color: brightness == Brightness.dark
                                ? AppTheme.homeTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => context.push('/shell/wink-plus'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusPill),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFE37B), Color(0xFFF5C76B)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.premiumGold.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 20, color: Color(0xFF6E4500)),
                          const SizedBox(width: 8),
                          Text(
                            'Unlock more with Wink+',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6E4500),
                            ),
                          ),
                        ],
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
}
