import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/features/home/home_screen.dart';
import 'package:winkidoo/models/judge_pack.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/pack_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/pack_service.dart';

class PackDetailScreen extends ConsumerWidget {
  const PackDetailScreen({super.key, required this.packSlug});

  final String packSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packAsync = ref.watch(packBySlugProvider(packSlug));
    final activePack = ref.watch(coupleActivePackProvider).value;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: CosmicBackground(
        glowColor: AppTheme.primaryOrange,
        child: SafeArea(
          child: packAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryOrange),
            ),
            error: (_, __) => Center(
              child: Text('Could not load pack.',
                  style: GoogleFonts.inter(color: AppTheme.textMuted)),
            ),
            data: (pack) {
              if (pack == null) {
                return Center(
                  child: Text('Pack not found.',
                      style: GoogleFonts.inter(color: AppTheme.textMuted)),
                );
              }

              final isActive = activePack?.id == pack.id;
              final overridesAsync =
                  ref.watch(packJudgeOverridesProvider(pack.id));

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(height: 16),

                    // Pack header
                    Center(
                      child: Column(
                        children: [
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color:
                                        AppTheme.success.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: AppTheme.success,
                                ),
                              ),
                            ),
                          Text(
                            pack.name,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.homeTextPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (pack.tagline != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              pack.tagline!,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppTheme.homeTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    if (pack.description != null) ...[
                      Text(
                        pack.description!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.homeTextSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Stats row
                    Row(
                      children: [
                        if (pack.bpMultiplier > 1.0)
                          _StatChip(
                            label: '${pack.bpMultiplier}x BP',
                            color: AppTheme.success,
                          ),
                        if (pack.isSeasonal && pack.daysRemaining >= 0) ...[
                          const SizedBox(width: 8),
                          _StatChip(
                            label: '${pack.daysRemaining}d left',
                            color: AppTheme.primaryOrangeLight,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Themed judges
                    Text(
                      'THEMED JUDGES',
                      style: AppTheme.overline(brightness).copyWith(
                        color: AppTheme.homeTextSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    overridesAsync.when(
                      loading: () => const SizedBox(
                        height: 80,
                        child: Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryOrange),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (overrides) {
                        if (overrides.isEmpty) {
                          return Text(
                            'All standard judges available.',
                            style: GoogleFonts.inter(
                                color: AppTheme.textMuted, fontSize: 13),
                          );
                        }
                        return Column(
                          children: overrides.values.map((o) {
                            final baseName =
                                HomeScreen.personaDisplayName(o.judgePersona);
                            return _JudgeOverrideCard(
                              baseName: baseName,
                              overrideName: o.overrideName ?? baseName,
                              overrideTagline: o.overrideTagline,
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Activate / Deactivate CTA
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: isActive
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    AppTheme.ctaOrangeA,
                                    AppTheme.ctaOrangeB,
                                  ],
                                ),
                          color: isActive
                              ? AppTheme.glassFill
                              : null,
                          border: isActive
                              ? Border.all(color: AppTheme.glassBorder)
                              : null,
                          boxShadow: isActive
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppTheme.ctaOuterGlow
                                        .withValues(alpha: 0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: MaterialButton(
                          onPressed: () => _togglePack(context, ref, pack, isActive),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Text(
                            isActive ? 'Deactivate Pack' : 'Activate Pack',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? AppTheme.homeTextPrimary
                                  : const Color(0xFF4A2800),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _togglePack(
    BuildContext context,
    WidgetRef ref,
    JudgePack pack,
    bool isActive,
  ) async {
    HapticFeedback.lightImpact();
    final couple = ref.read(coupleProvider).value;
    if (couple == null) return;

    final client = ref.read(supabaseClientProvider);
    await PackService.setCoupleActivePack(
      client,
      couple.id,
      isActive ? null : pack.id,
    );
    ref.invalidate(coupleActivePackProvider);
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _JudgeOverrideCard extends StatelessWidget {
  const _JudgeOverrideCard({
    required this.baseName,
    required this.overrideName,
    this.overrideTagline,
  });

  final String baseName;
  final String overrideName;
  final String? overrideTagline;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: brightness == Brightness.dark
            ? AppTheme.glassFill
            : AppTheme.lightGlassFill,
        border: Border.all(
          color: brightness == Brightness.dark
              ? AppTheme.glassBorder
              : AppTheme.lightGlassBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overrideName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.homeTextPrimary,
                  ),
                ),
                if (overrideTagline != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    overrideTagline!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.homeTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  'Based on $baseName',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
