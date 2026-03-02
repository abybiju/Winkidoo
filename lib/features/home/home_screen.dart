import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/achievement_icons.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/avatar_chip_row.dart';
import 'package:winkidoo/core/widgets/pill_cta.dart';
import 'package:winkidoo/core/widgets/wink_card.dart';
import 'package:winkidoo/core/widgets/winkidoo_top_bar.dart';
import 'package:winkidoo/features/profile/achievement_unlocked_dialog.dart';
import 'package:winkidoo/features/season/season_recap_screen.dart';
import 'package:winkidoo/models/achievement.dart';
import 'package:winkidoo/models/judge.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/providers/achievements_provider.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/judges_provider.dart';
import 'package:winkidoo/providers/season_recap_provider.dart';
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

  Future<void> _checkNewUnlocks(
      BuildContext context, List<Achievement> achievements) async {
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
      BuildContext context, SeasonRecap? recap) async {
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final couple = ref.watch(coupleProvider).value;
    final surprises = ref.watch(surprisesListProvider).value ?? [];
    final judgesAsync = ref.watch(activeJudgesProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    final seasonRecapAsync = ref.watch(seasonRecapProvider);

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
    final myVault = surprises.where((s) => s.creatorId == user?.id).toList();
    final resolved = surprises
        .where((s) => s.battleStatus == 'resolved')
        .toList()
      ..sort((a, b) => (b.lastActivityAt ?? b.unlockedAt ?? b.createdAt)
          .compareTo(a.lastActivityAt ?? a.unlockedAt ?? a.createdAt));
    final recent = resolved.take(4).toList();

    const fallbackJudge = Judge(
      id: 'fallback',
      personaId: AppConstants.personaSassyCupid,
      name: 'Sassy Cupid',
      tagline: 'Witty, warm, and a little sassy',
    );
    final judge = judgesAsync.value?.isNotEmpty == true
        ? judgesAsync.value!.first
        : fallbackJudge;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.gradientColors(Theme.of(context).brightness),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WinkidooTopBar(
                  notificationCount: math.min(waitingForMe.length, 9),
                  onNotificationTap: () => context.go('/shell/vault'),
                  onProfileTap: () => context.go('/shell/profile'),
                ),
                const SizedBox(height: 14),
                Text(
                  'Ready to play?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                AvatarChipRow(
                  items: [
                    const AvatarChipData(
                        label: 'You', isNew: true, color: Color(0xFFFFB24E)),
                    AvatarChipData(
                        label: couple?.isLinked == true ? 'Partner' : 'Invite',
                        badge: couple?.isLinked == true ? '1' : null,
                        color: const Color(0xFFE85D93)),
                    const AvatarChipData(
                        label: 'Maya', color: Color(0xFF8D5BF3)),
                    const AvatarChipData(
                        label: 'Drew', color: Color(0xFFFF8A66)),
                    const AvatarChipData(
                        label: 'Jack', color: Color(0xFF7B6DFA)),
                  ],
                ),
                const SizedBox(height: 16),
                _BattleHeroCard(
                  onStart: () => context.go('/shell/vault'),
                  partnerReady: waitingForMe.isNotEmpty,
                ),
                const SizedBox(height: 18),
                _SectionHeader(
                    title: 'Your Vault',
                    onTap: () => context.go('/shell/vault')),
                const SizedBox(height: 8),
                _VaultSummaryCard(
                  coupleLinked: couple?.isLinked == true,
                  waitingCount: waitingForMe.length,
                  myCount: myVault.length,
                  onTap: () => context.go('/shell/vault'),
                ),
                const SizedBox(height: 14),
                _SectionHeader(
                    title: 'Judge Spotlight',
                    onTap: () => context.push('/shell/create')),
                const SizedBox(height: 8),
                _JudgeSpotlightCard(
                  judge: judge,
                  onTap: () => context.push('/shell/create'),
                ),
                const SizedBox(height: 14),
                _SectionHeader(
                    title: 'Recent Wins',
                    onTap: () => context.go('/shell/vault')),
                const SizedBox(height: 8),
                _RecentWinsCard(surprises: recent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onTap,
          child: Text(
            'see all',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.76),
            ),
          ),
        ),
      ],
    );
  }
}

class _BattleHeroCard extends StatelessWidget {
  const _BattleHeroCard({
    required this.onStart,
    required this.partnerReady,
  });

  final VoidCallback onStart;
  final bool partnerReady;

  @override
  Widget build(BuildContext context) {
    return WinkCard(
      borderRadius: 34,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _VersusAvatar(
                  letter: 'Y',
                  colorA: Color(0xFFFFAF61),
                  colorB: Color(0xFFE85D93)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF6D2E8C),
                  child: Text('VS',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              _VersusAvatar(
                  letter: 'P',
                  colorA: Color(0xFF6C63FF),
                  colorB: Color(0xFFE85D93)),
            ],
          ),
          const SizedBox(height: 14),
          PillCta(
            label: partnerReady ? 'Start a Battle' : 'Invite to Battle',
            onTap: onStart,
            icon: Icons.local_fire_department_rounded,
          ),
          const SizedBox(height: 10),
          Text(
            partnerReady
                ? 'Challenge your partner and uncover your next memory.'
                : 'No active challenge yet. Go to Vault and create one.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersusAvatar extends StatelessWidget {
  const _VersusAvatar({
    required this.letter,
    required this.colorA,
    required this.colorB,
  });

  final String letter;
  final Color colorA;
  final Color colorB;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [colorA, colorB]),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Text(
        letter,
        style: GoogleFonts.poppins(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _VaultSummaryCard extends StatelessWidget {
  const _VaultSummaryCard({
    required this.coupleLinked,
    required this.waitingCount,
    required this.myCount,
    required this.onTap,
  });

  final bool coupleLinked;
  final int waitingCount;
  final int myCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WinkCard(
      borderRadius: 30,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            coupleLinked ? 'Vault linked and active' : 'Vault not linked yet',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$waitingCount waiting for you • $myCount from you',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: PillCta(
              label: 'Enter Vault',
              onTap: onTap,
              icon: Icons.chevron_right_rounded,
              trailing: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _JudgeSpotlightCard extends StatelessWidget {
  const _JudgeSpotlightCard({
    required this.judge,
    required this.onTap,
  });

  final Judge judge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WinkCard(
      borderRadius: 30,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: judge.primaryColor.withValues(alpha: 0.25),
                child: Icon(Icons.favorite_rounded,
                    color: judge.primaryColor, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judge.name,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      judge.tagline ??
                          'Witty, warm, and ready for your best persuasion.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Try persuading ${judge.name} tonight',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              PillCta(
                label: 'Explore Judges',
                compact: true,
                onTap: onTap,
                icon: Icons.chevron_right_rounded,
                trailing: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentWinsCard extends StatelessWidget {
  const _RecentWinsCard({required this.surprises});

  final List<Surprise> surprises;

  @override
  Widget build(BuildContext context) {
    return WinkCard(
      borderRadius: 30,
      child: surprises.isEmpty
          ? Text(
              'No resolved battles yet. Your first win will appear here.',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.75),
              ),
            )
          : Column(
              children: surprises.map((s) {
                final label = HomeScreen.personaDisplayName(s.judgePersona);
                final date = s.lastActivityAt ?? s.unlockedAt ?? s.createdAt;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFE165),
                        ),
                        child: const Icon(Icons.emoji_events_rounded,
                            color: Color(0xFF8C5D00), size: 21),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '${date.month}/${date.day}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
