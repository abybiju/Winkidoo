import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surprisesAsync = ref.watch(surprisesListProvider);
    final couple = ref.watch(coupleProvider).value;

    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded,
                          color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Our Journey',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: surprisesAsync.when(
                  data: (surprises) {
                    final milestones = _buildMilestones(surprises, couple?.linkedAt);
                    if (milestones.isEmpty) {
                      return Center(
                        child: Text(
                          'Your journey starts with\nyour first surprise 💝',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: milestones.length,
                      itemBuilder: (context, i) {
                        final m = milestones[i];
                        final isLast = i == milestones.length - 1;
                        return _TimelineTile(
                          milestone: m,
                          isLast: isLast,
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryPink),
                  ),
                  error: (_, __) =>
                      const Center(child: Text('Error loading journey')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_Milestone> _buildMilestones(
      List<Surprise> surprises, DateTime? linkedAt) {
    final milestones = <_Milestone>[];

    if (linkedAt != null) {
      milestones.add(_Milestone(
        emoji: '💑',
        title: 'You linked up',
        subtitle: 'Your couple journey began',
        date: linkedAt,
      ));
    }

    // Sort surprises oldest first for milestone scanning
    final sorted = [...surprises]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final resolved = sorted.where((s) => s.battleStatus == 'resolved').toList();

    // First surprise created
    if (sorted.isNotEmpty) {
      milestones.add(_Milestone(
        emoji: '🎁',
        title: 'First surprise created',
        subtitle: 'The vaults opened for the first time',
        date: sorted.first.createdAt,
      ));
    }

    // First battle win
    final firstWin =
        resolved.where((s) => s.winner == 'seeker').firstOrNull;
    if (firstWin != null) {
      milestones.add(_Milestone(
        emoji: '🏆',
        title: 'First battle won',
        subtitle: 'The seeker prevailed!',
        date: firstWin.resolvedAt ?? firstWin.createdAt,
      ));
    }

    // First quest surprise
    final firstQuest =
        sorted.where((s) => s.isQuestSurprise).firstOrNull;
    if (firstQuest != null) {
      milestones.add(_Milestone(
        emoji: '🗺️',
        title: 'First Love Quest started',
        subtitle: 'Your quest adventure began',
        date: firstQuest.createdAt,
      ));
    }

    // First collaborative surprise
    final firstCollab =
        sorted.where((s) => s.isCollaborative).firstOrNull;
    if (firstCollab != null) {
      milestones.add(_Milestone(
        emoji: '🤝',
        title: 'First collab surprise',
        subtitle: 'You built something together',
        date: firstCollab.createdAt,
      ));
    }

    // Every 5th resolved battle
    for (int i = 4; i < resolved.length; i += 5) {
      final s = resolved[i];
      milestones.add(_Milestone(
        emoji: '⚔️',
        title: 'Battle #${i + 1}',
        subtitle: '${i + 1} battles played together',
        date: s.resolvedAt ?? s.createdAt,
      ));
    }

    milestones.sort((a, b) => a.date.compareTo(b.date));
    return milestones;
  }
}

class _Milestone {
  const _Milestone({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.date,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final DateTime date;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.milestone, required this.isLast});

  final _Milestone milestone;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final date = milestone.date.toLocal();
    final dateStr =
        '${date.day}/${date.month}/${date.year}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryPink.withValues(alpha: 0.15),
                    border: Border.all(
                        color: AppTheme.primaryPink.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Text(milestone.emoji,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppTheme.primaryPink.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      milestone.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.primaryPink.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
