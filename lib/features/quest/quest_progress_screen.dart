import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/pill_cta.dart';
import 'package:winkidoo/features/home/home_screen.dart';
import 'package:winkidoo/models/quest.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/quest_provider.dart';

/// Displays quest progress: completed steps, current step, upcoming steps.
/// Lets the user add the next surprise or enter a battle for a pending one.
class QuestProgressScreen extends ConsumerWidget {
  const QuestProgressScreen({super.key, required this.questId});

  final String questId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questAsync = ref.watch(questByIdProvider(questId));
    final surprisesAsync = ref.watch(questSurprisesProvider(questId));
    final brightness = Theme.of(context).brightness;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.gradientColors(brightness),
          ),
        ),
        child: SafeArea(
          child: questAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryPink),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ),
            data: (quest) {
              if (quest == null) {
                return Center(
                  child: Text('Quest not found',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface)),
                );
              }
              return surprisesAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryPink),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface)),
                ),
                data: (surprises) => _QuestProgressBody(
                  quest: quest,
                  surprises: surprises,
                  currentUserId: currentUser?.id,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuestProgressBody extends StatelessWidget {
  const _QuestProgressBody({
    required this.quest,
    required this.surprises,
    required this.currentUserId,
  });

  final Quest quest;
  final List<Surprise> surprises;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded,
                    color: Theme.of(context).colorScheme.onSurface),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${HomeScreen.personaDisplayName(quest.judgePersona)} \u{2022} Step ${quest.currentStep + 1}/${quest.totalSteps}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (quest.isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.premiumGold.withValues(alpha: 0.2),
                  ),
                  child: Text(
                    'Completed!',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.premiumGold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: quest.progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryPink),
            ),
          ),
        ),
        // Steps list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: quest.totalSteps,
            itemBuilder: (context, index) {
              final surprise =
                  index < surprises.length ? surprises[index] : null;
              final isCurrentStep = index == quest.currentStep;
              final isCompleted = surprise != null &&
                  surprise.battleStatus == 'resolved';
              final isBoss = index == quest.totalSteps - 1;
              final isCreator = surprise?.creatorId == currentUserId;

              return _StepCard(
                stepIndex: index,
                isCurrentStep: isCurrentStep && quest.isActive,
                isCompleted: isCompleted,
                isBoss: isBoss,
                surprise: surprise,
                isCreator: isCreator,
                quest: quest,
              );
            },
          ),
        ),
        // Action button
        if (quest.isActive)
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildActionButton(context),
          ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final currentStepSurprise = quest.currentStep < surprises.length
        ? surprises[quest.currentStep]
        : null;

    if (currentStepSurprise == null) {
      // No surprise created for this step yet — show "Add Surprise"
      return PillCta(
        label: quest.isBossBattle
            ? 'Create Boss Battle Surprise \u{1F525}'
            : 'Add Step ${quest.currentStep + 1} Surprise',
        onTap: () {
          context.push('/shell/create', extra: {
            'questId': quest.id,
            'questStep': quest.currentStep,
            'judgePersona': quest.judgePersona,
            'difficulty': quest.currentDifficulty,
          });
        },
      );
    }

    if (currentStepSurprise.battleStatus == 'active' &&
        currentStepSurprise.creatorId != currentUserId) {
      // Seeker can enter battle
      return PillCta(
        label: quest.isBossBattle
            ? 'Enter Boss Battle \u{2694}\u{FE0F}'
            : 'Enter Battle',
        onTap: () {
          context.push('/shell/battle/${currentStepSurprise.id}');
        },
      );
    }

    if (currentStepSurprise.battleStatus == 'active' &&
        currentStepSurprise.creatorId == currentUserId) {
      return Text(
        'Waiting for your partner to battle...',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.6),
        ),
        textAlign: TextAlign.center,
      );
    }

    return const SizedBox.shrink();
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.stepIndex,
    required this.isCurrentStep,
    required this.isCompleted,
    required this.isBoss,
    required this.surprise,
    required this.isCreator,
    required this.quest,
  });

  final int stepIndex;
  final bool isCurrentStep;
  final bool isCompleted;
  final bool isBoss;
  final Surprise? surprise;
  final bool isCreator;
  final Quest quest;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isCurrentStep
            ? AppTheme.primaryPink.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: isCompleted ? 0.06 : 0.04),
        border: Border.all(
          color: isCurrentStep
              ? AppTheme.primaryPink.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
          width: isCurrentStep ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Step indicator
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppTheme.primaryPink
                  : isCurrentStep
                      ? AppTheme.premiumGold
                      : Colors.white.withValues(alpha: 0.1),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 20)
                  : Text(
                      isBoss ? '\u{1F451}' : '${stepIndex + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: isBoss ? 16 : 14,
                        fontWeight: FontWeight.w700,
                        color: isCurrentStep
                            ? Colors.black87
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Step info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBoss
                      ? 'Boss Battle'
                      : 'Step ${stepIndex + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (surprise != null)
                  Text(
                    isCompleted
                        ? (surprise!.winner == 'seeker'
                            ? 'Unlocked!'
                            : 'Defended')
                        : isCreator
                            ? 'You hid a surprise'
                            : 'Waiting for you to unlock',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  )
                else if (isCurrentStep)
                  Text(
                    'Ready to add a surprise',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.primaryPink.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          // Difficulty indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => Icon(
                Icons.star_rounded,
                size: 14,
                color: i < quest.currentDifficulty
                    ? AppTheme.premiumGold
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
