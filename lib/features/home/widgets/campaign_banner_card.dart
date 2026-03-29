import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/campaign.dart';
import 'package:winkidoo/models/campaign_progress.dart';
import 'package:winkidoo/providers/campaign_provider.dart';

class CampaignBannerCard extends ConsumerWidget {
  const CampaignBannerCard({
    super.key,
    required this.onTap,
    required this.onBrowseCampaigns,
    this.compact = false,
  });

  final void Function(String campaignId) onTap;
  final VoidCallback onBrowseCampaigns;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressesAsync = ref.watch(activeCampaignProgressesProvider);
    final campaignsAsync = ref.watch(activeCampaignsProvider);

    return progressesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (progresses) {
        if (progresses.isNotEmpty) {
          // Show active campaign progress
          return _ActiveCampaignBanner(
            progress: progresses.first,
            campaignsAsync: campaignsAsync,
            onTap: onTap,
            compact: compact,
          );
        }
        // No active campaign — show browse CTA if campaigns exist
        return campaignsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (campaigns) {
            if (campaigns.isEmpty) return const SizedBox.shrink();
            return _BrowseCampaignsBanner(
              onTap: onBrowseCampaigns,
              compact: compact,
            );
          },
        );
      },
    );
  }
}

class _ActiveCampaignBanner extends StatelessWidget {
  const _ActiveCampaignBanner({
    required this.progress,
    required this.campaignsAsync,
    required this.onTap,
    this.compact = false,
  });

  final CampaignProgress progress;
  final AsyncValue<List<Campaign>> campaignsAsync;
  final void Function(String campaignId) onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // Find campaign name from the list
    final campaigns = campaignsAsync.value ?? [];
    final campaign = campaigns
        .where((c) => c.id == progress.campaignId)
        .firstOrNull;
    final title = campaign?.title ?? 'Story Mode';
    final totalChapters = campaign?.totalChapters ?? 5;

    return GestureDetector(
      onTap: () => onTap(progress.campaignId),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.vaultHeroGradient(brightness),
          ),
          border: Border.all(
            color: AppTheme.secondaryViolet.withValues(alpha: 0.25),
          ),
          boxShadow: AppTheme.elevation2(brightness),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF9B7DFF), Color(0xFF7C5CFC)],
                ),
              ),
              child: const Icon(Icons.auto_stories_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 14 : 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.homeTextPrimary,
                    ),
                  ),
                  Text(
                    'Chapter ${progress.currentChapter} of $totalChapters',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.secondaryViolet,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _BrowseCampaignsBanner extends StatelessWidget {
  const _BrowseCampaignsBanner({
    required this.onTap,
    this.compact = false,
  });

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
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
            const Icon(Icons.auto_stories_rounded,
                color: AppTheme.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Story Mode Campaigns',
                style: GoogleFonts.inter(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.homeTextPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
