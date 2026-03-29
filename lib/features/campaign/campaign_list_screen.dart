import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/features/home/home_screen.dart';
import 'package:winkidoo/models/campaign.dart';
import 'package:winkidoo/providers/campaign_provider.dart';

class CampaignListScreen extends ConsumerWidget {
  const CampaignListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(activeCampaignsProvider);

    return Scaffold(
      body: CosmicBackground(
        glowColor: AppTheme.secondaryViolet,
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
                      'Story Mode',
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
                  'Narrative adventures with your partner. Complete chapters to unlock exclusive rewards.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.homeTextSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: campaignsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.secondaryViolet),
                  ),
                  error: (_, __) => Center(
                    child: Text('Could not load campaigns.',
                        style: GoogleFonts.inter(color: AppTheme.textMuted)),
                  ),
                  data: (campaigns) {
                    if (campaigns.isEmpty) {
                      return Center(
                        child: Text('No campaigns available yet.',
                            style:
                                GoogleFonts.inter(color: AppTheme.textMuted)),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      itemCount: campaigns.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _CampaignCard(
                          campaign: campaigns[index],
                          onTap: () => context
                              .push('/shell/campaign/${campaigns[index].id}'),
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

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign, required this.onTap});

  final Campaign campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final personaName = HomeScreen.personaDisplayName(campaign.judgePersona);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 130),
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
                      AppTheme.secondaryViolet.withValues(alpha: 0.06),
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
                        Text(
                          campaign.title,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.homeTextPrimary,
                          ),
                        ),
                        if (campaign.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            campaign.subtitle!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.homeTextSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _InfoChip(
                              label: '${campaign.totalChapters} chapters',
                              color: AppTheme.secondaryViolet,
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              label: personaName,
                              color: AppTheme.primaryOrangeLight,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textMuted, size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
