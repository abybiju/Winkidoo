import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/models/judge_pack.dart';
import 'package:winkidoo/providers/pack_provider.dart';

class PackListScreen extends ConsumerWidget {
  const PackListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(activePacksProvider);

    return Scaffold(
      body: CosmicBackground(
        glowColor: AppTheme.primaryOrange,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Battle Packs',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.homeTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Themed judge personas, dares, and visuals. Activate a pack to transform your experience.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.homeTextSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: packsAsync.when(
                  loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryOrange),
                  ),
                  error: (_, __) => Center(
                    child: Text(
                      'Could not load packs.',
                      style: GoogleFonts.inter(color: AppTheme.textMuted),
                    ),
                  ),
                  data: (packs) {
                    if (packs.isEmpty) {
                      return Center(
                        child: Text(
                          'No packs available yet. Stay tuned!',
                          style: GoogleFonts.inter(color: AppTheme.textMuted),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      itemCount: packs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _PackCard(
                          pack: packs[index],
                          onTap: () =>
                              context.push('/shell/packs/${packs[index].slug}'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({required this.pack, required this.onTap});

  final JudgePack pack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.vaultHeroGradient(brightness),
          ),
          border: Border.all(color: AppTheme.premiumBorder30(brightness)),
          boxShadow: AppTheme.elevation3(brightness),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppTheme.homeGlowPink.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              pack.name,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.homeTextPrimary,
                              ),
                            ),
                            if (pack.isPremium) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.premiumAmber
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'WINK+',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.premiumAmber,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (pack.tagline != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            pack.tagline!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.homeTextSecondary,
                            ),
                          ),
                        ],
                        if (pack.isSeasonal && pack.daysRemaining >= 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${pack.daysRemaining} days remaining',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryOrangeLight,
                            ),
                          ),
                        ],
                        if (pack.bpMultiplier > 1.0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${pack.bpMultiplier}x Battle Pass points',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textMuted,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
