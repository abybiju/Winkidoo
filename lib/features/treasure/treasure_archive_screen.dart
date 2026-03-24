import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/constants/judge_asset_map.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/judge.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/models/treasure_archive.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/judges_provider.dart';
import 'package:winkidoo/providers/treasure_archive_provider.dart';
import 'package:winkidoo/providers/user_profile_provider.dart';

class TreasureArchiveScreen extends ConsumerWidget {
  const TreasureArchiveScreen({super.key});

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  static String _difficultyLabel(int level) {
    if (level <= 1) return 'Easy';
    if (level <= 3) return 'Medium';
    return 'Hard';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archiveWithSurprises = ref.watch(archiveWithSurprisesProvider);
    final isWinkPlus = ref.watch(effectiveWinkPlusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Treasure Archive'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.homeBackgroundGradient(Theme.of(context).brightness),
          ),
        ),
        child: archiveWithSurprises.when(
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 64,
                        color: AppTheme.primary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No treasures yet',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep battles in Treasure after you win to revisit them here.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final item = list[i];
                return _TreasureCard(
                  archive: item.archive,
                  surprise: item.surprise,
                  isWinkPlus: isWinkPlus,
                  formatDate: _formatDate,
                  difficultyLabel: _difficultyLabel,
                  onTap: () => context.push(
                    '/shell/treasure-archive/${item.archive.surpriseId}',
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not load archive',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(archiveWithSurprisesProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TreasureCard extends ConsumerWidget {
  const _TreasureCard({
    required this.archive,
    required this.surprise,
    required this.isWinkPlus,
    required this.formatDate,
    required this.difficultyLabel,
    required this.onTap,
  });

  final TreasureArchive archive;
  final Surprise? surprise;
  final bool isWinkPlus;
  final String Function(DateTime) formatDate;
  final String Function(int) difficultyLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final judgeAsync =
        ref.watch(judgeByPersonaIdProvider(archive.judgePersona));
    final userGender = ref.watch(userProfileMetaProvider).gender;
    final judge = judgeAsync.value ?? Judge.placeholder(archive.judgePersona);

    final seekerScore = surprise?.seekerScore ?? 0;
    final resistanceScore = surprise?.resistanceScore ?? 0;
    final maxScore = AppConstants.seekerScoreMax;
    final difficultyLevel = surprise?.difficultyLevel ?? 2;

    Widget cardContent = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: judge.primaryColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppTheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _JudgePortrait(judge: judge, userGender: userGender),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  judge.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _WinnerBadge(
                                    winner: archive.winner ?? surprise?.winner),
                                const SizedBox(height: 4),
                                Text(
                                  '${formatDate(archive.archivedAt)} · ${difficultyLabel(difficultyLevel)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
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
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${archive.attemptsCount} attempts',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (surprise != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              '${surprise!.creatorDefenseCount} defenses',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      _MiniMeter(
                        seekerScore: seekerScore,
                        resistanceScore: resistanceScore,
                        maxScore: maxScore,
                        accentColor: judge.primaryColor,
                      ),
                    ],
                  ),
                ),
                if (!isWinkPlus)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.15),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_rounded,
                                  size: 40,
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.9),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Unlock with Wink+',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return cardContent;
  }
}

class _JudgePortrait extends StatelessWidget {
  const _JudgePortrait({required this.judge, required this.userGender});

  final Judge judge;
  final String userGender;

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = JudgeAssetResolver.resolveAvatarPath(
      judge: judge,
      userGender: userGender,
    );
    return SizedBox(
      width: 56,
      height: 56,
      child: resolvedAvatar.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                resolvedAvatar,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(context),
              ),
            )
          : _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    final initial = judge.name.isNotEmpty ? judge.name[0] : '?';
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: judge.primaryColor.withValues(alpha: 0.4),
        border: Border.all(
          color: judge.accentColor.withValues(alpha: 0.8),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: judge.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _WinnerBadge extends StatelessWidget {
  const _WinnerBadge({this.winner});

  final String? winner;

  @override
  Widget build(BuildContext context) {
    final isSeekerWin = winner == 'seeker';
    final label = isSeekerWin ? 'Seeker won' : 'Vault held';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSeekerWin
            ? AppTheme.primary.withValues(alpha: 0.2)
            : AppTheme.secondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSeekerWin ? AppTheme.primary : AppTheme.secondary,
        ),
      ),
    );
  }
}

class _MiniMeter extends StatelessWidget {
  const _MiniMeter({
    required this.seekerScore,
    required this.resistanceScore,
    required this.maxScore,
    required this.accentColor,
  });

  final int seekerScore;
  final int resistanceScore;
  final int maxScore;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final max = maxScore <= 0 ? 1.0 : maxScore.toDouble();
    final seekerFraction = (seekerScore / max).clamp(0.0, 1.0);
    final resistanceFraction = (resistanceScore / max).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final seekerWidth = w * seekerFraction;
        final resistanceLeft = w * resistanceFraction;
        return SizedBox(
          height: 6,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: w,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              SizedBox(
                width: seekerWidth,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (resistanceLeft > 0 && resistanceLeft < w)
                Positioned(
                  left: resistanceLeft - 1,
                  top: -1,
                  bottom: -1,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
