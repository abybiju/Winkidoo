import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/core/widgets/stagger_entrance.dart';
import 'package:winkidoo/core/widgets/winkidoo_top_bar.dart';
import 'package:winkidoo/features/home/widgets/campaign_banner_card.dart';
import 'package:winkidoo/features/home/widgets/daily_dare_card.dart';
import 'package:winkidoo/features/home/widgets/judge_spotlight_card.dart';
import 'package:winkidoo/features/home/widgets/pack_banner_card.dart';
import 'package:winkidoo/features/minigame/mini_game_card.dart';
import 'package:winkidoo/features/minigame/mini_game_play_sheet.dart';
import 'package:winkidoo/features/dare/dare_response_sheet.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/models/judge.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/daily_dare_provider.dart';
import 'package:winkidoo/providers/judges_provider.dart';
import 'package:winkidoo/providers/mini_game_provider.dart';
import 'package:winkidoo/providers/streak_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/providers/xp_provider.dart';

class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  double _clamped(double width, double factor, double min, double max) {
    return (width * factor).clamp(min, max).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final surprises = ref.watch(surprisesListProvider).value ?? [];
    final judgesAsync = ref.watch(activeJudgesProvider);
    final streakAsync = ref.watch(streakProvider);
    final xpAsync = ref.watch(coupleXpProvider);

    final waitingForMe = surprises
        .where((s) => s.creatorId != user?.id && !s.isUnlocked)
        .toList();

    final streakWeeks = streakAsync.value?.currentStreak ?? 0;
    final levelCount = xpAsync.value?.currentLevel ?? 0;

    const fallbackJudge = Judge(
      id: 'fallback',
      personaId: AppConstants.personaSassyCupid,
      name: 'Judge Wizard',
      tagline: 'Feeling magical. Feeling judgey.',
    );
    final judge = judgesAsync.value?.isNotEmpty == true
        ? judgesAsync.value!.first
        : fallbackJudge;
    final spotlightJudges = judgesAsync.value?.isNotEmpty == true
        ? judgesAsync.value!
        : const [fallbackJudge];

    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 380;
    final horizontal = isCompact ? 12.0 : 16.0;
    final gap = isCompact ? 10.0 : 14.0;
    final contentWidth = (width - (horizontal * 2)).clamp(320.0, 760.0);

    final dareHeight = _clamped(contentWidth, 0.33, 168, 214);
    final gameHeight = _clamped(contentWidth, 0.33, 168, 214);
    final judgeHeight = _clamped(contentWidth, 0.33, 168, 214);

    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: CosmicBackground(
        showStars: true,
        glowColor: AppTheme.primaryOrange,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 126),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WinkidooTopBar(
                      matchLogoToWordmark: true,
                      notificationCount: math.min(waitingForMe.length, 9),
                      streakCount: streakWeeks,
                      levelCount: levelCount,
                      onNotificationTap: () => context.go('/shell/vault'),
                      onStreakTap: () => context.go('/shell/profile'),
                    ),
                    SizedBox(height: gap + 4),

                    // Section header
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 10),
                      child: Text(
                        'Daily Activities',
                        style: GoogleFonts.poppins(
                          fontSize: isCompact ? 18 : 20,
                          fontWeight: FontWeight.w700,
                          color: brightness == Brightness.dark
                              ? AppTheme.homeTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),

                    StaggerEntrance(
                      index: 0,
                      child: DailyDareCard(
                        compact: isCompact,
                        height: dareHeight,
                        onTakeDare: () {
                          final dare = ref.read(dailyDareProvider).value?.dare;
                          if (dare == null) return;
                          showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => DareResponseSheet(dare: dare),
                          );
                        },
                        onViewResult: () =>
                            context.push('/shell/dare/result'),
                      ),
                    ),
                    SizedBox(height: gap),
                    StaggerEntrance(
                      index: 1,
                      child: MiniGameCard(
                        compact: isCompact,
                        height: gameHeight,
                        onPlay: () {
                          final game = ref.read(miniGameProvider).value?.game;
                          if (game == null) return;
                          showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => MiniGamePlaySheet(game: game),
                          );
                        },
                        onViewResult: () =>
                            context.push('/shell/minigame/result'),
                      ),
                    ),

                    SizedBox(height: gap + 8),

                    // Section header
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 10),
                      child: Text(
                        'Adventures',
                        style: GoogleFonts.poppins(
                          fontSize: isCompact ? 18 : 20,
                          fontWeight: FontWeight.w700,
                          color: brightness == Brightness.dark
                              ? AppTheme.homeTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),

                    StaggerEntrance(
                      index: 2,
                      child: PackBannerCard(
                        compact: isCompact,
                        onExplorePacks: () => context.push('/shell/packs'),
                      ),
                    ),
                    SizedBox(height: gap),
                    StaggerEntrance(
                      index: 3,
                      child: CampaignBannerCard(
                        compact: isCompact,
                        onTap: (campaignId) =>
                            context.push('/shell/campaign/$campaignId'),
                        onBrowseCampaigns: () =>
                            context.push('/shell/campaigns'),
                      ),
                    ),

                    SizedBox(height: gap + 8),

                    // Section header
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 10),
                      child: Text(
                        'Judges',
                        style: GoogleFonts.poppins(
                          fontSize: isCompact ? 18 : 20,
                          fontWeight: FontWeight.w700,
                          color: brightness == Brightness.dark
                              ? AppTheme.homeTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),

                    StaggerEntrance(
                      index: 4,
                      child: JudgeSpotlightCard(
                        judge: judge,
                        judges: spotlightJudges,
                        onExplore: () => context.push('/shell/create'),
                        compact: isCompact,
                        height: judgeHeight,
                      ),
                    ),

                    SizedBox(height: gap + 8),

                    // Section header
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 10),
                      child: Text(
                        'Social',
                        style: GoogleFonts.poppins(
                          fontSize: isCompact ? 18 : 20,
                          fontWeight: FontWeight.w700,
                          color: brightness == Brightness.dark
                              ? AppTheme.homeTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),

                    StaggerEntrance(
                      index: 5,
                      child: _CharacterChatCard(
                        brightness: brightness,
                        isCompact: isCompact,
                        onTap: () => context.push('/shell/chat'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterChatCard extends StatelessWidget {
  const _CharacterChatCard({
    required this.brightness,
    required this.isCompact,
    required this.onTap,
  });

  final Brightness brightness;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isCompact ? 14 : 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: brightness == Brightness.dark
              ? AppTheme.glassFill
              : Colors.white.withValues(alpha: 0.70),
          border: Border.all(
            color: brightness == Brightness.dark
                ? AppTheme.glassBorderOrange
                : AppTheme.lightGlassBorder,
          ),
          boxShadow: AppTheme.elevation1(brightness),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppTheme.primaryOrange.withValues(alpha: 0.15),
              ),
              child: const Icon(
                PhosphorIconsFill.chatTeardropDots,
                color: AppTheme.primaryOrange,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Character Chat',
                    style: GoogleFonts.poppins(
                      fontSize: isCompact ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      color: brightness == Brightness.dark
                          ? AppTheme.homeTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chat as Trump, Shakespeare, Yoda & more!',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: brightness == Brightness.dark
                          ? AppTheme.homeTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.primaryOrange, size: 22),
          ],
        ),
      ),
    );
  }
}
