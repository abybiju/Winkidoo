import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/achievement_icons.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/profile/achievement_unlocked_dialog.dart';
import 'package:winkidoo/features/season/season_recap_screen.dart';
import 'package:winkidoo/models/achievement.dart';
import 'package:winkidoo/models/couple.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/providers/achievements_provider.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/season_recap_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/providers/winks_provider.dart';
import 'package:winkidoo/services/achievement_storage_service.dart';
import 'package:winkidoo/services/season_recap_storage_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Single guard so recap and achievement checks run at most once per load.
  /// Recap is shown first, then achievement modal (if both qualify).
  bool _checkedHomeCelebrations = false;

  Future<void> _checkNewUnlocks(BuildContext context, List<Achievement> achievements) async {
    final seen = await AchievementStorageService.getSeenAchievements();
    final newlyUnlocked = achievements
        .where((a) => a.unlocked && !seen.contains(a.id))
        .toList();
    final firstNew = newlyUnlocked.isEmpty ? null : newlyUnlocked.first;
    if (firstNew == null || !context.mounted) return;
    final icon = achievementIcons[firstNew.id] ?? Icons.emoji_events_rounded;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AchievementUnlockedDialog(achievement: firstNew, icon: icon),
    );
    if (context.mounted) await AchievementStorageService.markAsSeen(firstNew.id);
  }

  Future<void> _checkSeasonRecap(BuildContext context, SeasonRecap? recap) async {
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

  /// Runs once per load: season recap first (if unseen), then achievement modal (if any).
  Future<void> _runCelebrationSequence(
    BuildContext context,
    SeasonRecap? recap,
    List<Achievement> achievements,
  ) async {
    await _checkSeasonRecap(context, recap);
    if (context.mounted) await _checkNewUnlocks(context, achievements);
  }

  static String _personaDisplayName(String id) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final couple = ref.watch(coupleProvider).value;
    final winks = ref.watch(winksBalanceProvider).value;
    final surprises = ref.watch(surprisesListProvider).value ?? [];
    final achievementsAsync = ref.watch(achievementsProvider);
    final seasonRecapAsync = ref.watch(seasonRecapProvider);

    // Run at most once per load; recap takes priority over achievement modal.
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

    final waitingForMe = surprises.where((s) => s.creatorId != user?.id && !s.isUnlocked).toList();
    final recentResolved = surprises.where((s) => s.battleStatus == 'resolved').toList()
      ..sort((a, b) => (b.lastActivityAt ?? b.unlockedAt ?? b.createdAt).compareTo(a.lastActivityAt ?? a.unlockedAt ?? a.createdAt));
    final recent = recentResolved.take(5).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.gradientColors(Theme.of(context).brightness),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(couple: couple),
                const SizedBox(height: 20),
                _WinkBalanceCard(balance: winks?.balance ?? 0),
                const SizedBox(height: 16),
                _NewSurpriseCard(count: waitingForMe.length, onTap: () => context.go('/shell/vault')),
                const SizedBox(height: 16),
                _QuickActions(
                  onCreateSurprise: () => context.push('/shell/create'),
                  onEnterVault: () => context.go('/shell/vault'),
                ),
                const SizedBox(height: 20),
                _JudgeSpotlight(),
                const SizedBox(height: 20),
                _RecentBattleCard(surprises: recent, onTap: (s) => context.go('/shell/vault')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.couple});

  final Couple? couple;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
          child: Text(
            'W',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Your vault',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _WinkBalanceCard extends StatelessWidget {
  const _WinkBalanceCard({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.emoji_emotions_rounded, color: AppTheme.accent, size: 28),
            const SizedBox(width: 12),
            Text(
              '$balance Winks',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewSurpriseCard extends StatelessWidget {
  const _NewSurpriseCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: count > 0 ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surface.withValues(alpha: 0.8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    count > 0 ? Icons.mail_rounded : Icons.inbox_rounded,
                    color: count > 0 ? AppTheme.primary : AppTheme.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    count > 0 ? 'New surprise waiting' : 'No new surprises',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (count > 0) ...[
                const SizedBox(height: 4),
                Text(
                  count == 1 ? '1 surprise from your partner' : '$count surprises from your partner',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onCreateSurprise,
    required this.onEnterVault,
  });

  final VoidCallback onCreateSurprise;
  final VoidCallback onEnterVault;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onCreateSurprise,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Create Surprise'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEnterVault,
            icon: const Icon(Icons.inbox_rounded, size: 20),
            label: const Text('Enter Vault'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _JudgeSpotlight extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Judge Spotlight',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  child: Icon(Icons.favorite_rounded, color: AppTheme.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sassy Cupid',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Witty, warm, and a little sassy',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentBattleCard extends StatelessWidget {
  const _RecentBattleCard({required this.surprises, required this.onTap});

  final List<Surprise> surprises;
  final void Function(Surprise) onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent battles',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (surprises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No battles yet',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            else
              ...surprises.map(
                (s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.emoji_events_rounded, color: AppTheme.accent, size: 22),
                  title: Text(
                    HomeScreen._personaDisplayName(s.judgePersona),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    s.winner != null ? 'Resolved' : '—',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  onTap: () => onTap(s),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
