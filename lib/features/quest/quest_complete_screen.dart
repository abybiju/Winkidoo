import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/pill_cta.dart';
import 'package:winkidoo/features/home/home_screen.dart';
import 'package:winkidoo/models/quest.dart';
import 'package:winkidoo/providers/quest_provider.dart';

/// Celebration screen shown when a Love Quest is completed.
class QuestCompleteScreen extends ConsumerStatefulWidget {
  const QuestCompleteScreen({super.key, required this.questId});

  final String questId;

  @override
  ConsumerState<QuestCompleteScreen> createState() =>
      _QuestCompleteScreenState();
}

class _QuestCompleteScreenState extends ConsumerState<QuestCompleteScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _confettiController.play());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questAsync = ref.watch(questByIdProvider(widget.questId));
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryPink),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (quest) {
                  if (quest == null) {
                    return const Center(child: Text('Quest not found'));
                  }
                  return _CompletionBody(quest: quest);
                },
              ),
            ),
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.2,
              colors: const [
                AppTheme.primaryPink,
                AppTheme.premiumGold,
                AppTheme.plum,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionBody extends StatelessWidget {
  const _CompletionBody({required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy
            Text(
              '\u{1F3C6}',
              style: const TextStyle(fontSize: 72),
            ),
            const SizedBox(height: 20),
            Text(
              'Quest Complete!',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppTheme.premiumGold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              quest.title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${quest.totalSteps} steps completed with ${HomeScreen.personaDisplayName(quest.judgePersona)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Stats card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: AppTheme.premiumGold.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  _statRow('Steps',
                      '${quest.totalSteps}/${quest.totalSteps}'),
                  const SizedBox(height: 8),
                  _statRow('Difficulty',
                      'Lvl ${quest.difficultyStart} \u{2192} Lvl ${quest.difficultyEnd}'),
                  const SizedBox(height: 8),
                  _statRow('Judge',
                      HomeScreen.personaDisplayName(quest.judgePersona)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PillCta(
              label: 'Back to Home',
              onTap: () => context.go('/shell/home'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/shell/quest/${quest.id}'),
              child: Text(
                'View Quest Details',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryPink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Builder(
      builder: (context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
