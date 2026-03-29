import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/features/home/home_screen.dart';
import 'package:winkidoo/models/campaign_chapter.dart';
import 'package:winkidoo/providers/campaign_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/campaign_service.dart';

class CampaignDetailScreen extends ConsumerWidget {
  const CampaignDetailScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(campaignDetailProvider(campaignId));
    final progressAsync = ref.watch(campaignProgressProvider(campaignId));
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: CosmicBackground(
        showStars: true,
        glowColor: AppTheme.secondaryViolet,
        child: SafeArea(
          child: detailAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.secondaryViolet),
            ),
            error: (_, __) => Center(
              child: Text('Could not load campaign.',
                  style: GoogleFonts.inter(color: AppTheme.textMuted)),
            ),
            data: (data) {
              if (data == null) {
                return Center(
                  child: Text('Campaign not found.',
                      style: GoogleFonts.inter(color: AppTheme.textMuted)),
                );
              }

              final (campaign, chapters) = data;
              final progress = progressAsync.value;
              final currentChapter = progress?.currentChapter ?? 0;
              final isStarted = progress != null;
              final isCompleted = progress?.isCompleted ?? false;
              final personaName =
                  HomeScreen.personaDisplayName(campaign.judgePersona);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(height: 16),

                    // Campaign header
                    Center(
                      child: Column(
                        children: [
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.premiumAmber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppTheme.premiumAmber
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'COMPLETED',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: AppTheme.premiumAmber,
                                ),
                              ),
                            ),
                          Text(
                            campaign.title,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.homeTextPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (campaign.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(campaign.subtitle!,
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: AppTheme.homeTextSecondary)),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Led by $personaName  •  ${campaign.totalChapters} chapters',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (campaign.description != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        campaign.description!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.homeTextSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Chapter list
                    Text(
                      'CHAPTERS',
                      style: AppTheme.overline(brightness).copyWith(
                        color: AppTheme.homeTextSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...chapters.map((chapter) {
                      final isUnlocked = !isStarted
                          ? chapter.chapterNumber == 1
                          : chapter.chapterNumber <= currentChapter;
                      final isCurrent = isStarted &&
                          chapter.chapterNumber == currentChapter &&
                          !isCompleted;
                      final isDone = isStarted &&
                          chapter.chapterNumber < currentChapter;

                      return _ChapterCard(
                        chapter: chapter,
                        isUnlocked: isUnlocked,
                        isCurrent: isCurrent,
                        isDone: isDone || isCompleted,
                        onTap: isUnlocked
                            ? () => context.push(
                                '/shell/campaign/$campaignId/intro/${chapter.chapterNumber}')
                            : null,
                      );
                    }),

                    const SizedBox(height: 24),

                    // Start / Continue CTA
                    if (!isCompleted)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9B7DFF), Color(0xFF7C5CFC)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondaryViolet
                                    .withValues(alpha: 0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: MaterialButton(
                            onPressed: () =>
                                _startOrContinue(context, ref, isStarted),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Text(
                              isStarted ? 'Continue Campaign' : 'Start Campaign',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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

  Future<void> _startOrContinue(
    BuildContext context,
    WidgetRef ref,
    bool isStarted,
  ) async {
    HapticFeedback.lightImpact();

    if (!isStarted) {
      final couple = ref.read(coupleProvider).value;
      if (couple == null) return;
      final client = ref.read(supabaseClientProvider);
      await CampaignService.startCampaign(client, couple.id, campaignId);
      ref.invalidate(campaignProgressProvider(campaignId));
      ref.invalidate(activeCampaignProgressesProvider);
    }

    final progress = await ref.read(campaignProgressProvider(campaignId).future);
    if (context.mounted && progress != null) {
      context.push(
          '/shell/campaign/$campaignId/intro/${progress.currentChapter}');
    }
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
    required this.isUnlocked,
    required this.isCurrent,
    required this.isDone,
    this.onTap,
  });

  final CampaignChapter chapter;
  final bool isUnlocked;
  final bool isCurrent;
  final bool isDone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final opacity = isUnlocked ? 1.0 : 0.45;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isCurrent
                ? AppTheme.secondaryViolet.withValues(alpha: 0.1)
                : (brightness == Brightness.dark
                    ? AppTheme.glassFill
                    : AppTheme.lightGlassFill),
            border: Border.all(
              color: isCurrent
                  ? AppTheme.secondaryViolet.withValues(alpha: 0.4)
                  : (brightness == Brightness.dark
                      ? AppTheme.glassBorder
                      : AppTheme.lightGlassBorder),
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Chapter number circle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppTheme.success.withValues(alpha: 0.15)
                      : isCurrent
                          ? AppTheme.secondaryViolet.withValues(alpha: 0.15)
                          : AppTheme.glassFill,
                  border: Border.all(
                    color: isDone
                        ? AppTheme.success
                        : isCurrent
                            ? AppTheme.secondaryViolet
                            : AppTheme.glassBorder,
                  ),
                ),
                alignment: Alignment.center,
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: AppTheme.success, size: 18)
                    : Text(
                        '${chapter.chapterNumber}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCurrent
                              ? AppTheme.secondaryViolet
                              : AppTheme.textMuted,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.homeTextPrimary,
                      ),
                    ),
                    Text(
                      '${chapter.questCount} quests  •  Difficulty ${chapter.difficultyStart}-${chapter.difficultyEnd}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isUnlocked)
                const Icon(Icons.lock_rounded,
                    color: AppTheme.textMuted, size: 18),
              if (isCurrent)
                const Icon(Icons.play_arrow_rounded,
                    color: AppTheme.secondaryViolet, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
