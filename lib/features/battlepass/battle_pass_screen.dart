import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/battle_pass_provider.dart';
import 'package:winkidoo/services/battle_pass_service.dart';

class BattlePassScreen extends ConsumerWidget {
  const BattlePassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passAsync = ref.watch(battlePassProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.homeBackgroundGradient(brightness),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded,
                          color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Battle Pass',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: passAsync.when(
                  data: (pass) {
                    if (pass == null) {
                      return Center(
                        child: Text(
                          'No active season right now.',
                          style: GoogleFonts.inter(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    }
                    final nextTier = BattlePassTier.nextTierPoints(pass.points);
                    final progress = pass.points / nextTier;
                    final daysLeft =
                        pass.seasonEnd.difference(DateTime.now()).inDays;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Season header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF5C76B), Color(0xFFFF6B2C)],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pass.seasonName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$daysLeft days remaining',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Current tier
                          Row(
                            children: [
                              Text(
                                BattlePassTier.emoji(pass.tier),
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${pass.tier[0].toUpperCase()}${pass.tier.substring(1)} Tier',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  Text(
                                    '${pass.points} pts',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Progress bar
                          if (pass.tier != 'gold') ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor:
                                    AppTheme.primaryPink.withValues(alpha: 0.10),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        AppTheme.primaryPink),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${pass.points} / $nextTier pts to next tier',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ] else
                            Text(
                              '🏆 Max tier reached! You\'re legendary.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFF5C76B),
                              ),
                            ),

                          const SizedBox(height: 32),

                          // How to earn points
                          Text(
                            'How to Earn Points',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...[
                            ('🎁 Create a Surprise', '+5 pts'),
                            ('⚔️ Win a Battle', '+10 pts'),
                            ('🗺️ Quest Step', '+5 pts'),
                            ('🏁 Complete a Quest', '+25 pts'),
                          ].map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item.$1,
                                        style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface)),
                                    Text(item.$2,
                                        style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryPink)),
                                  ],
                                ),
                              )),

                          const SizedBox(height: 32),

                          // Tier rewards
                          Text(
                            'Tier Rewards',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...[
                            ('🥉 Bronze', '0 pts', 'Starter badge'),
                            ('🥈 Silver', '100 pts', '+25 Winks bonus'),
                            ('🥇 Gold', '250 pts', '+75 Winks + exclusive judge skin'),
                          ].map((item) {
                            final isActive = (item.$1.contains('Bronze') &&
                                    pass.tier == 'bronze') ||
                                (item.$1.contains('Silver') &&
                                    pass.tier == 'silver') ||
                                (item.$1.contains('Gold') &&
                                    pass.tier == 'gold');
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                color: isActive
                                    ? AppTheme.primaryPink
                                        .withValues(alpha: 0.12)
                                    : (brightness == Brightness.dark
                                        ? AppTheme.glassFill
                                        : Colors.white.withValues(alpha: 0.50)),
                                border: Border.all(
                                  color: isActive
                                      ? AppTheme.primaryPink
                                      : (brightness == Brightness.dark
                                          ? AppTheme.glassBorderSubtle
                                          : AppTheme.lightGlassBorder),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(item.$1,
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface)),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(item.$2,
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.5))),
                                      Text(item.$3,
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isActive
                                                  ? AppTheme.primaryPink
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.7))),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryPink)),
                  error: (_, __) => const Center(child: Text('Error loading')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
