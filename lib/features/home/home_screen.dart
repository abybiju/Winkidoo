import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/models/quest.dart';
import 'package:go_router/go_router.dart';
import 'package:winkidoo/core/constants/achievement_icons.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/profile_completion_sheet.dart';
import 'package:winkidoo/core/widgets/warm_kit.dart';
import 'package:winkidoo/features/home/widgets/avatar_selector.dart';
import 'package:winkidoo/features/home/widgets/hero_section.dart';
import 'package:winkidoo/core/widgets/stagger_entrance.dart';
import 'package:winkidoo/features/home/widgets/recent_wins_section.dart';
import 'package:winkidoo/features/profile/achievement_unlocked_dialog.dart';
import 'package:winkidoo/features/season/season_recap_screen.dart';
import 'package:winkidoo/models/achievement.dart';
import 'package:winkidoo/providers/achievements_provider.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/quest_provider.dart';
import 'package:winkidoo/providers/season_recap_provider.dart';
import 'package:winkidoo/providers/streak_provider.dart';
import 'package:winkidoo/providers/notification_provider.dart';
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

  Future<void> _goToCreateWithProfileGate({String? coupleId}) async {
    final ok = await ensureProfileComplete(context, ref);
    if (!mounted || !ok) return;
    context.push('/shell/create',
        extra: coupleId != null ? {'coupleId': coupleId} : null);
  }

  /// Handles a tap on the home avatar rail: the Invite tile opens the friends
  /// screen; a friend avatar starts a surprise for that friend pair.
  void _onAvatarTap(HomeAvatarOption option) {
    if (option.type == HomeAvatarType.invite) {
      context.push('/shell/chat/add-friends');
      return;
    }
    _goToCreateWithProfileGate(coupleId: option.coupleId);
  }

  /// Builds the avatar rail from the user's real friends (+ an Invite tile).
  List<HomeAvatarOption> _friendAvatarOptions(List<FriendPair> pairs) {
    final colors = [
      AppTheme.primaryOrangeLight,
      AppTheme.primaryOrange,
      AppTheme.premiumAmber,
      AppTheme.primaryPink,
      AppTheme.secondaryViolet,
    ];
    final options = <HomeAvatarOption>[];
    for (var i = 0; i < pairs.length; i++) {
      final p = pairs[i];
      // Only network (uploaded) avatars render an image; presets/none show the
      // colored initial.
      final url = (p.avatarMode == 'upload') ? p.avatarUrl : null;
      options.add(HomeAvatarOption(
        label: p.name,
        type: HomeAvatarType.regular,
        color: colors[i % colors.length],
        avatarUrl: (url != null && url.isNotEmpty) ? url : null,
        coupleId: p.coupleId,
      ));
    }
    options.add(const HomeAvatarOption(
      label: 'Add',
      type: HomeAvatarType.invite,
      isHot: true,
    ));
    return options;
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

  double _clamped(double width, double factor, double min, double max) {
    return (width * factor).clamp(min, max).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final surprises = ref.watch(surprisesListProvider).value ?? [];
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

    final resolved = surprises
        .where((s) => s.battleStatus == 'resolved')
        .toList()
      ..sort((a, b) => (b.lastActivityAt ?? b.unlockedAt ?? b.createdAt)
          .compareTo(a.lastActivityAt ?? a.unlockedAt ?? a.createdAt));
    final recent = resolved.take(8).toList();

    // Surprises waiting for ME to battle (mirror of the vault's "waiting" set).
    final waiting = surprises
        .where((s) =>
            s.creatorId != user?.id &&
            !s.isUnlocked &&
            !(s.isCollaborative && s.collabPartnerStatus == 'awaiting'))
        .toList();
    // A battle I've already started (in progress) vs. a fresh sealed one.
    final inProgress = waiting
        .where((s) =>
            s.battleStatus == 'active' &&
            s.lastActivityAt != null &&
            s.seekerScore > 0)
        .toList()
      ..sort((a, b) => (b.lastActivityAt ?? b.createdAt)
          .compareTo(a.lastActivityAt ?? a.createdAt));
    final freshWaiting =
        waiting.where((s) => !inProgress.contains(s)).toList();
    final heroWaiting =
        freshWaiting.isNotEmpty ? freshWaiting.first : (waiting.isNotEmpty ? waiting.first : null);
    final activeBattle = inProgress.isNotEmpty ? inProgress.first : null;

    final friendPairs = ref.watch(friendPairsProvider).value ?? const [];
    final partner = friendPairs.isNotEmpty ? friendPairs.first : null;

    final streakWeeks = streakAsync.value?.currentStreak ?? 0;

    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 380;
    final horizontal = isCompact ? 12.0 : 16.0;
    final gap = isCompact ? 10.0 : 14.0;
    final contentWidth = (width - (horizontal * 2)).clamp(320.0, 760.0);

    final heroHeight = _clamped(contentWidth, 0.22, 132, 170);
    final recentItemHeight = _clamped(contentWidth, 0.14, 88, 108);

    return Scaffold(
      body: OrbitField(
        cx: 0.5,
        cy: 0.14,
        intensity: 0.9,
        rings: 4,
        baseR: 64,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 126),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _greetingBar(
                      context,
                      user,
                      ref.watch(unreadNotificationCountProvider),
                    ),
                    SizedBox(height: gap),
                    _duoOrbit(context, user, partner),
                    const SizedBox(height: 14),
                    _statusChips(context, streakWeeks, partner != null),
                    SizedBox(height: gap + 8),
                    if (heroWaiting != null)
                      _waitingCard(context, heroWaiting)
                    else
                      _noWaitingCard(context),
                    if (activeBattle != null) ...[
                      SizedBox(height: gap + 10),
                      _sectionHeader(context, 'Your active battle', '1'),
                      const SizedBox(height: 12),
                      _activeBattleCard(context, activeBattle),
                    ],
                    SizedBox(height: gap + 10),
                    // Kept: friend rail (pick a duo to seal a surprise for).
                    HeroSection(
                      height: heroHeight,
                      items: _friendAvatarOptions(friendPairs),
                      onAvatarTap: _onAvatarTap,
                    ),
                    SizedBox(height: gap),
                    StaggerEntrance(
                      index: 1,
                      child: _QuestSection(questsAsync: questsAsync),
                    ),
                    SizedBox(height: gap),
                    StaggerEntrance(
                      index: 2,
                      child: RecentWins(
                        surprises: recent,
                        judgeNameForPersona: HomeScreen.personaDisplayName,
                        onSeeAll: () => context.go('/shell/vault'),
                        itemHeight: recentItemHeight,
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

  // ── new warm-glass hero pieces (real data) ──────────────────────

  String _firstName(dynamic user) {
    final meta = user?.userMetadata;
    final dn = meta?['display_name'] ?? meta?['full_name'] ?? meta?['name'];
    if (dn is String && dn.trim().isNotEmpty) return dn.trim().split(' ').first;
    final email = user?.email;
    if (email is String && email.isNotEmpty) return email.split('@').first;
    return 'there';
  }

  Widget _greetingBar(BuildContext context, dynamic user, int unread) {
    final name = _firstName(user);
    final greeting = TimeOfDay.now().hour < 12
        ? 'morning'
        : (TimeOfDay.now().hour < 18 ? 'afternoon' : 'evening');
    return Row(
      children: [
        GradientAvatar(initial: name.substring(0, 1).toUpperCase(), size: 42),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonoLabel('Tuesday $greeting'),
            const SizedBox(height: 2),
            Text('Hey, $name',
                style: AppTheme.heading3(Theme.of(context).brightness)
                    .copyWith(fontSize: 17)),
          ],
        ),
        const Spacer(),
        _bell(context, unread),
      ],
    );
  }

  Widget _bell(BuildContext context, int unread) {
    return GestureDetector(
      onTap: () => context.push('/shell/notifications'),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.warmGlassBg,
          border: Border.all(color: AppTheme.warmLine),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded,
                size: 21, color: AppTheme.warmInk70),
            if (unread > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryOrange,
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.7),
                          blurRadius: 8),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _duoOrbit(BuildContext context, dynamic user, FriendPair? partner) {
    final me = _firstName(user).substring(0, 1).toUpperCase();
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // connecting dotted arc
          CustomPaint(
            size: const Size(220, 90),
            painter: _ArcPainter(),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GradientAvatar(initial: me, size: 70, glow: true),
                  const SizedBox(height: 8),
                  Text('You',
                      style: AppTheme.subheading(Theme.of(context).brightness)
                          .copyWith(fontSize: 13)),
                ],
              ),
              const SizedBox(width: 36),
              GestureDetector(
                onTap: () => partner == null
                    ? context.push('/shell/chat/add-friends')
                    : _goToCreateWithProfileGate(coupleId: partner.coupleId),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GradientAvatar(
                      initial: partner != null
                          ? partner.name.substring(0, 1).toUpperCase()
                          : '+',
                      size: 70,
                      glow: partner != null,
                      gradient: partner != null
                          ? const [Color(0xFFC9A0FF), Color(0xFF7A4DFF)]
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(partner?.name ?? 'Invite',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.subheading(Theme.of(context).brightness)
                            .copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          // heart on the arc
          Positioned(
            top: 24,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.warmBg0,
                border: Border.all(color: AppTheme.warmLine),
              ),
              child: const Icon(Icons.favorite_rounded,
                  size: 15, color: AppTheme.primaryOrange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChips(BuildContext context, int streak, bool linked) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (linked)
          WarmChip(
            label: 'Linked',
            tone: WarmTone.ok,
            icon: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppTheme.warmOk),
            ),
          ),
        if (linked && streak > 0) const SizedBox(width: 8),
        if (streak > 0)
          WarmChip(
            label: '$streak-day streak',
            tone: WarmTone.orange,
            icon: const Icon(Icons.local_fire_department_rounded,
                size: 13, color: AppTheme.orangeHi),
          ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String label, String trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MonoLabel(label),
        MonoLabel(trailing, color: AppTheme.warmInk45),
      ],
    );
  }

  Widget _waitingCard(BuildContext context, dynamic surprise) {
    final judge = HomeScreen.personaDisplayName(surprise.judgePersona as String);
    final diff = _difficultyLabel(surprise.difficultyLevel as int);
    return WarmCard(
      glow: 0.45,
      padding: const EdgeInsets.all(20),
      tint: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.primaryOrange.withValues(alpha: 0.18),
          AppTheme.orangeDeep.withValues(alpha: 0.04),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const WarmChip(
                label: 'Waiting for you',
                tone: WarmTone.orange,
                icon: Icon(Icons.lock_rounded, size: 12, color: AppTheme.orangeHi),
              ),
              MonoLabel(diff, color: AppTheme.orangeHi),
            ],
          ),
          const SizedBox(height: 14),
          const HighlightHeadline('A {surprise} is sealed for you.', size: 25),
          const SizedBox(height: 14),
          Row(
            children: [
              GradientAvatar(
                  initial: _judgeInitial(surprise.judgePersona as String),
                  size: 34,
                  gradient: _judgeGradient(surprise.judgePersona as String)),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppTheme.bodyMedium(Theme.of(context).brightness)
                        .copyWith(fontSize: 13),
                    children: [
                      const TextSpan(text: 'Judge '),
                      TextSpan(
                          text: judge,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.warmInk)),
                      const TextSpan(text: ' is guarding it'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlossyButton(
            label: 'Enter the battle',
            full: true,
            onTap: () => context.push('/shell/battle/${surprise.id}'),
          ),
        ],
      ),
    );
  }

  Widget _noWaitingCard(BuildContext context) {
    return WarmCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HighlightHeadline('Nothing {waiting} — yet.', size: 23),
          const SizedBox(height: 8),
          Text('Seal a surprise and make them earn it.',
              style: AppTheme.bodyMedium(Theme.of(context).brightness)),
          const SizedBox(height: 16),
          GlossyButton(
            label: 'Seal a surprise',
            onTap: () => _goToCreateWithProfileGate(),
            icon: Icons.lock_rounded,
          ),
        ],
      ),
    );
  }

  Widget _activeBattleCard(BuildContext context, dynamic surprise) {
    final judge = HomeScreen.personaDisplayName(surprise.judgePersona as String);
    return WarmCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/shell/battle/${surprise.id}'),
      child: Column(
        children: [
          Row(
            children: [
              GradientAvatar(
                  initial: _judgeInitial(surprise.judgePersona as String),
                  size: 44,
                  gradient: _judgeGradient(surprise.judgePersona as String)),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(judge,
                        style: AppTheme.heading3(Theme.of(context).brightness)
                            .copyWith(fontSize: 14.5)),
                    const SizedBox(height: 1),
                    Text('Your battle · in progress',
                        style: AppTheme.bodyMedium(Theme.of(context).brightness)
                            .copyWith(fontSize: 12, color: AppTheme.warmInk45)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.warmInk45, size: 22),
            ],
          ),
          const SizedBox(height: 14),
          WarmMeter(level: _meterLevel(surprise.seekerScore as int), compact: true),
        ],
      ),
    );
  }

  String _difficultyLabel(int level) {
    if (level <= 1) return 'Easy';
    if (level == 2) return 'Medium';
    if (level == 3) return 'Hard';
    return 'Brutal';
  }

  int _meterLevel(int seekerScore) => (seekerScore ~/ 20).clamp(0, 4);

  String _judgeInitial(String persona) {
    switch (persona) {
      case AppConstants.personaSassyCupid:
        return '♥';
      case AppConstants.personaChaosGremlin:
        return '★';
      case AppConstants.personaDrLove:
        return '✦';
      default:
        return HomeScreen.personaDisplayName(persona).substring(0, 1);
    }
  }

  List<Color> _judgeGradient(String persona) {
    switch (persona) {
      case AppConstants.personaSassyCupid:
        return const [Color(0xFFFF9EC8), Color(0xFFFF5E9C)];
      case AppConstants.personaChaosGremlin:
        return AppTheme.orbGradient;
      case AppConstants.personaDrLove:
        return AppTheme.goldGradient;
      default:
        return AppTheme.orbGradient;
    }
  }
}

/// Dotted arc connecting the two duo avatars on the home orbit.
class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.primaryOrange.withValues(alpha: 0.6);
    final path = Path()
      ..moveTo(size.width * 0.14, size.height * 0.55)
      ..cubicTo(size.width * 0.35, 0, size.width * 0.65, 0,
          size.width * 0.86, size.height * 0.55);
    // dashed
    final dash = Path();
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        dash.addPath(
            metric.extractPath(dist, dist + 0.5), Offset.zero);
        dist += 8;
      }
    }
    canvas.drawPath(dash, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => false;
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
          final brightness = Theme.of(context).brightness;
          return GestureDetector(
            onTap: () => context.push('/shell/quest/create'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                color: brightness == Brightness.dark
                    ? AppTheme.glassFill
                    : Colors.white.withValues(alpha: 0.70),
                border: Border.all(
                  color: AppTheme.primaryPink.withValues(alpha: 0.20),
                ),
                boxShadow: AppTheme.elevation1(brightness),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🗺️ Duo Quest',
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
                          .withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      color: AppTheme.primaryPink.withValues(alpha: 0.15),
                    ),
                    child: const Text(
                      'Start Duo Quest ⚔️',
                      style: TextStyle(
                        fontSize: 13,
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
        final brightness = Theme.of(context).brightness;
        return GestureDetector(
          onTap: () => context.push('/shell/quest/${activeQuest.id}'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              color: brightness == Brightness.dark
                  ? AppTheme.glassFill
                  : Colors.white.withValues(alpha: 0.70),
              border: Border.all(
                color: AppTheme.primaryOrange.withValues(alpha: 0.22),
              ),
              boxShadow: AppTheme.elevation1(brightness),
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
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryOrange,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        color: AppTheme.primaryPink.withValues(alpha: 0.15),
                      ),
                      child: Text(
                        'Step ${activeQuest.currentStep}/${activeQuest.totalSteps}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(
                    activeQuest.totalSteps,
                    (index) {
                      final isCompleted = index < activeQuest.currentStep;
                      final isCurrent = index == activeQuest.currentStep;
                      return Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: isCurrent ? 14 : 12,
                              height: isCurrent ? 14 : 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted || isCurrent
                                    ? AppTheme.primaryOrange
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isCompleted || isCurrent
                                      ? AppTheme.primaryOrange
                                      : brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : Colors.black.withValues(alpha: 0.1),
                                  width: 1.5,
                                ),
                                boxShadow: isCompleted || isCurrent
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryOrange.withValues(alpha: 0.6),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : [],
                              ),
                            ),
                            if (index < activeQuest.totalSteps - 1)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: isCompleted
                                      ? AppTheme.primaryOrange.withValues(alpha: 0.6)
                                      : brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.black.withValues(alpha: 0.05),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$progress% complete',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: brightness == Brightness.dark
                        ? AppTheme.homeTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () {
        final brightness = Theme.of(context).brightness;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            color: brightness == Brightness.dark
                ? AppTheme.glassFill
                : Colors.white.withValues(alpha: 0.50),
            border: Border.all(
              color: brightness == Brightness.dark
                  ? AppTheme.glassBorderSubtle
                  : AppTheme.lightGlassBorder,
            ),
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
        );
      },
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
