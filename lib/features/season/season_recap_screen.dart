import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/achievement_icons.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/achievement.dart';
import 'package:winkidoo/providers/season_recap_provider.dart';

/// Full-screen Season Recap: 6 slides, no business logic, no DB, no navigation.
/// Caller passes precomputed [SeasonRecap] and [onFinish]; [onReplayHighlight] is optional.
class SeasonRecapScreen extends StatefulWidget {
  const SeasonRecapScreen({
    super.key,
    required this.recap,
    required this.onFinish,
    this.onReplayHighlight,
  });

  final SeasonRecap recap;
  final VoidCallback onFinish;
  final void Function(String surpriseId)? onReplayHighlight;

  @override
  State<SeasonRecapScreen> createState() => _SeasonRecapScreenState();
}

class _SeasonRecapScreenState extends State<SeasonRecapScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  void _onNextOrFinish() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final recap = widget.recap;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundStart,
              AppTheme.backgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _SlideSeasonIntro(
                      recap: recap,
                      gradientController: _gradientController,
                    ),
                    _SlidePerformanceSummary(recap: recap),
                    _SlideStreak(recap: recap),
                    _SlideAchievements(recap: recap),
                    _SlideHighlightDuel(
                      recap: recap,
                      onReplayHighlight: widget.onReplayHighlight,
                    ),
                    _SlideClosingCta(onFinish: widget.onFinish),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        6,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _currentPage
                                ? AppTheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _onNextOrFinish,
                      child: Text(
                        _currentPage < 5 ? 'Next' : 'Continue',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slide 1: Season title, judge portrait placeholder, subtitle, soft animated gradient.
class _SlideSeasonIntro extends StatelessWidget {
  const _SlideSeasonIntro({
    required this.recap,
    required this.gradientController,
  });

  final SeasonRecap recap;
  final AnimationController gradientController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: gradientController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                -1.0 + 0.3 * gradientController.value,
                -0.5,
              ),
              end: Alignment(
                1.0 - 0.2 * gradientController.value,
                1.0,
              ),
              colors: [
                AppTheme.backgroundStart,
                AppTheme.backgroundEnd,
                AppTheme.surface.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              recap.seasonTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 56,
              backgroundColor: AppTheme.surface,
              child: Icon(
                Icons.emoji_events_rounded,
                size: 56,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your story this season',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slide 2: Battles played, win rate, avg persuasion.
class _SlidePerformanceSummary extends StatelessWidget {
  const _SlidePerformanceSummary({required this.recap});

  final SeasonRecap recap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Performance',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 40),
          _StatRow(
            value: '${recap.battlesPlayed}',
            label: 'Battles Played',
          ),
          const SizedBox(height: 24),
          _StatRow(
            value: '${recap.winRate.toStringAsFixed(1)}%',
            label: 'Win Rate',
          ),
          const SizedBox(height: 24),
          _StatRow(
            value: recap.avgPersuasion.toStringAsFixed(1),
            label: 'Avg Persuasion',
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide 3: Longest streak, flame accent.
class _SlideStreak extends StatelessWidget {
  const _SlideStreak({required this.recap});

  final SeasonRecap recap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 64,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 24),
          Text(
            '${recap.longestStreakDuringSeason}',
            style: GoogleFonts.poppins(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Longest streak this season',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            recap.longestStreakDuringSeason == 1 ? 'week' : 'weeks',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide 4: Horizontal scroll of achievement badges (season unlocks only).
class _SlideAchievements extends StatelessWidget {
  const _SlideAchievements({required this.recap});

  final SeasonRecap recap;

  @override
  Widget build(BuildContext context) {
    final achievements = recap.achievementsUnlockedDuringSeason;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Achievements',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: achievements.isEmpty
                ? Center(
                    child: Text(
                      'No achievements unlocked this season',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: achievements.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final a = achievements[index];
                      final icon = achievementIcons[a.id] ?? Icons.star_rounded;
                      return _AchievementBadge(
                        achievement: a,
                        icon: icon,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({
    required this.achievement,
    required this.icon,
  });

  final Achievement achievement;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide 5: Highlight duel preview + Replay button if [highlightSurpriseId] exists.
class _SlideHighlightDuel extends StatelessWidget {
  const _SlideHighlightDuel({
    required this.recap,
    this.onReplayHighlight,
  });

  final SeasonRecap recap;
  final void Function(String surpriseId)? onReplayHighlight;

  @override
  Widget build(BuildContext context) {
    final hasHighlight = recap.highlightSurpriseId != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Highlight Duel',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          if (hasHighlight) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 48,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your top battle this season',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () =>
                  onReplayHighlight?.call(recap.highlightSurpriseId!),
              icon: const Icon(Icons.replay_rounded, size: 20),
              label: const Text('Replay This Battle'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
              ),
            ),
          ] else
            Text(
              'No highlight duel this season',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Slide 6: Closing CTA — "Next season begins now." + Continue.
class _SlideClosingCta extends StatelessWidget {
  const _SlideClosingCta({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Next season begins now.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onFinish,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
