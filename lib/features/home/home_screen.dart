import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/models/quest.dart';
import 'package:go_router/go_router.dart';
import 'package:winkidoo/core/constants/achievement_icons.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/profile_completion_sheet.dart';
import 'package:winkidoo/core/widgets/winkidoo_top_bar.dart';
import 'package:winkidoo/features/home/widgets/avatar_selector.dart';
import 'package:winkidoo/features/home/widgets/battle_card.dart';
import 'package:winkidoo/features/home/widgets/hero_section.dart';
import 'package:winkidoo/features/home/widgets/judge_spotlight_card.dart';
import 'package:winkidoo/features/home/widgets/recent_wins_section.dart';
import 'package:winkidoo/features/profile/achievement_unlocked_dialog.dart';
import 'package:winkidoo/features/season/season_recap_screen.dart';
import 'package:winkidoo/models/achievement.dart';
import 'package:winkidoo/models/judge.dart';
import 'package:winkidoo/providers/achievements_provider.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/judges_provider.dart';
import 'package:winkidoo/providers/quest_provider.dart';
import 'package:winkidoo/providers/season_recap_provider.dart';
import 'package:winkidoo/providers/streak_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/services/achievement_storage_service.dart';
import 'package:winkidoo/services/season_recap_storage_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();

  static String personaDisplayName(String id) {
    switch (id) {
      case AppConstants.personaSassyCupid:
        return 'Sassy Cupid';
      case AppConstants.personaPoeticRomantic:
        return 'Poetic Romantic';
      case AppConstants.personaChaosGremlin:
        return 'Chaos Gremlin';
      case AppConstants.personaTheEx:
        return 'The Ex';
      case AppConstants.personaDrLove:
        return 'Dr. Love';
      default:
        return id;
    }
  }
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _checkedHomeCelebrations = false;

  Future<void> _goToCreateWithProfileGate() async {
    final ok = await ensureProfileComplete(context, ref);
    if (!mounted || !ok) return;
    context.push('/shell/create');
  }

  Future<void> _checkNewUnlocks(
    BuildContext context,
    List<Achievement> achievements,
  ) async {
    final seen = await AchievementStorageService.getSeenAchievements();
    final firstNew = achievements
        .where((a) => a.unlocked && !seen.contains(a.id))
        .cast<Achievement?>()
        .firstWhere((a) => a != null, orElse: () => null);
    if (firstNew == null || !context.mounted) return;
    final icon = achievementIcons[firstNew.id] ?? Icons.emoji_events_rounded;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) =>
          AchievementUnlockedDialog(achievement: firstNew, icon: icon),
    );
    if (context.mounted) {
      await AchievementStorageService.markAsSeen(firstNew.id);
    }
  }

  Future<void> _checkSeasonRecap(
    BuildContext context,
    SeasonRecap? recap,
  ) async {
    if (recap == null || !context.mounted) return;
    final seen = await SeasonRecapStorageService.hasSeenSeason(recap.seasonId);
    if (seen || !context.mounted) return;
    final nav = Navigator.of(context);
    await nav.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SeasonRecapScreen(
          recap: recap,
          onFinish: () async {
            await SeasonRecapStorageService.markSeasonSeen(recap.seasonId);
            if (context.mounted) nav.pop();
          },
          onReplayHighlight: (surpriseId) {
            if (context.mounted) {
              nav.pop();
              context.push('/shell/treasure-archive/$surpriseId');
            }
          },
        ),
      ),
    );
  }

  Future<void> _runCelebrationSequence(
    BuildContext context,
    SeasonRecap? recap,
    List<Achievement> achievements,
  ) async {
    await _checkSeasonRecap(context, recap);
    if (context.mounted) await _checkNewUnlocks(context, achievements);
  }

  List<HomeAvatarOption> _avatarOptions() {
    return const [
      HomeAvatarOption(
        label: 'Ava',
        type: HomeAvatarType.regular,
        color: Color(0xFFFFBE66),
      ),
      HomeAvatarOption(
        label: 'Maya',
        type: HomeAvatarType.regular,
        color: Color(0xFFFF8A62),
      ),
      HomeAvatarOption(
        label: 'Kevin',
        type: HomeAvatarType.regular,
        color: Color(0xFFFFCF5E),
        badge: '3',
      ),
      HomeAvatarOption(
        label: 'Ria',
        type: HomeAvatarType.regular,
        color: Color(0xFF9C78FF),
      ),
      HomeAvatarOption(
        label: 'Add',
        type: HomeAvatarType.invite,
        isHot: true,
      ),
    ];
  }

  double _clamped(double width, double factor, double min, double max) {
    return (width * factor).clamp(min, max).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final surprises = ref.watch(surprisesListProvider).value ?? [];
    final judgesAsync = ref.watch(activeJudgesProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    final seasonRecapAsync = ref.watch(seasonRecapProvider);
    final streakAsync = ref.watch(streakProvider);
    final questsAsync = ref.watch(activeQuestsProvider);

    if (!_checkedHomeCelebrations &&
        achievementsAsync.hasValue &&
        seasonRecapAsync.hasValue) {
      _checkedHomeCelebrations = true;
      final recap = seasonRecapAsync.value;
      final achievements = achievementsAsync.value ?? [];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runCelebrationSequence(context, recap, achievements);
      });
    }

    final waitingForMe = surprises
        .where((s) => s.creatorId != user?.id && !s.isUnlocked)
        .toList();
    final resolved = surprises
        .where((s) => s.battleStatus == 'resolved')
        .toList()
      ..sort((a, b) => (b.lastActivityAt ?? b.unlockedAt ?? b.createdAt)
          .compareTo(a.lastActivityAt ?? a.unlockedAt ?? a.createdAt));
    final recent = resolved.take(8).toList();

    final streakWeeks = streakAsync.value?.currentStreak ?? 0;

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

    final heroHeight = _clamped(contentWidth, 0.22, 132, 170);
    final battleHeight = _clamped(contentWidth, 0.37, 188, 232);
    final judgeHeight = _clamped(contentWidth, 0.33, 168, 214);
    final recentItemHeight = _clamped(contentWidth, 0.14, 88, 108);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                AppTheme.homeBackgroundGradient(Theme.of(context).brightness),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.25),
                    radius: 1.1,
                    colors: [
                      AppTheme.homeGlowPink.withValues(alpha: 0.09),
                      AppTheme.homeGlowOrange.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
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
                          onNotificationTap: () => context.go('/shell/vault'),
                          onStreakTap: () => context.go('/shell/profile'),
                        ),
                        SizedBox(height: gap),
                        HeroSection(
                          height: heroHeight,
                          items: _avatarOptions(),
                          onAvatarTap: (_) => _goToCreateWithProfileGate(),
                        ),
                        SizedBox(height: gap),
                        BattleCard(
                          onInviteTap: _goToCreateWithProfileGate,
                          compact: isCompact,
                          height: battleHeight,
                        ),
                        SizedBox(height: gap),
                        JudgeSpotlightCard(
                          judge: judge,
                          judges: spotlightJudges,
                          onExplore: _goToCreateWithProfileGate,
                          compact: isCompact,
                          height: judgeHeight,
                        ),
                        SizedBox(height: gap),
                        _QuestSection(questsAsync: questsAsync),
                        SizedBox(height: gap),
                        RecentWins(
                          surprises: recent,
                          judgeNameForPersona: HomeScreen.personaDisplayName,
                          onSeeAll: () => context.go('/shell/vault'),
                          itemHeight: recentItemHeight,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestSection extends StatelessWidget {
  const _QuestSection({required this.questsAsync});

  final AsyncValue<List<Quest>> questsAsync;

  @override
  Widget build(BuildContext context) {
    return questsAsync.when(
      data: (quests) {
        final activeQuest = quests.firstWhere(
          (q) => q.status == AppConstants.questStatusActive,
          orElse: () => Quest.empty(),
        );

        if (activeQuest.isEmpty) {
          // No active quest - show CTA
          return GestureDetector(
            onTap: () => context.push('/shell/quest/create'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryPink.withValues(alpha: 0.15),
                    AppTheme.primaryPink.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.primaryPink.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🗺️ Love Quest',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryPink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a co-op surprise chain. Build together, unlock together.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppTheme.primaryPink.withValues(alpha: 0.2),
                    ),
                    child: const Text(
                      'Start Love Quest ⚔️',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryPink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Active quest - show progress
        final progress = (activeQuest.currentStep / activeQuest.totalSteps * 100)
            .toStringAsFixed(0);
        return GestureDetector(
          onTap: () => context.push('/shell/quest/${activeQuest.id}'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryPink.withValues(alpha: 0.2),
                  AppTheme.primaryPink.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: AppTheme.primaryPink.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activeQuest.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryPink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: AppTheme.primaryPink.withValues(alpha: 0.2),
                      ),
                      child: Text(
                        'Step ${activeQuest.currentStep}/${activeQuest.totalSteps}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryPink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: activeQuest.currentStep / activeQuest.totalSteps,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryPink,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$progress% complete',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: const SizedBox(
          height: 60,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
