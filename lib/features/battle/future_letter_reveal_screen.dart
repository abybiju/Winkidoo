import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/providers/ai_judge_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/judges_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/services/encryption_service.dart';

/// Reveal screen for Future Letter surprises.
/// Shows the original letter side-by-side with the AI's aged-judge rewrite.
class FutureLetterRevealScreen extends ConsumerStatefulWidget {
  const FutureLetterRevealScreen({super.key, required this.surpriseId});

  final String surpriseId;

  @override
  ConsumerState<FutureLetterRevealScreen> createState() =>
      _FutureLetterRevealScreenState();
}

class _FutureLetterRevealScreenState
    extends ConsumerState<FutureLetterRevealScreen> {
  late ConfettiController _confettiController;
  String? _originalLetter;
  String? _futureRewrite;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadAndTransform();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadAndTransform() async {
    try {
      final surprise =
          await ref.read(surpriseByIdProvider(widget.surpriseId).future);
      if (surprise == null) throw Exception('Surprise not found');

      final couple = ref.read(coupleProvider).value;
      final coupleId = couple?.id;

      // Decrypt the original letter
      final decrypted = await EncryptionService.decrypt(
        surprise.contentEncrypted,
        coupleId: coupleId,
      );
      setState(() => _originalLetter = decrypted);

      // Get the judge persona info for the rewrite
      final personaId =
          surprise.futureLetterJudgePersona ?? surprise.judgePersona;
      final judge =
          await ref.read(judgeByPersonaIdProvider(personaId).future);
      final personaName = judge?.name ?? 'The Judge';
      final personaTagline = judge?.tagline ?? 'A wise judge';
      final personaTone = judge?.toneTags.join(', ') ?? '';

      // Generate the aged rewrite
      final aiService = ref.read(aiJudgeServiceProvider);
      final rewrite = await aiService.rewriteAsFutureJudge(
        originalText: decrypted,
        personaName: personaName,
        personaPrompt:
            'Tagline: $personaTagline. Tone: $personaTone',
      );

      // Mark as unlocked + resolved
      await Supabase.instance.client.from('surprises').update({
        'is_unlocked': true,
        'unlocked_at': DateTime.now().toUtc().toIso8601String(),
        'battle_status': 'resolved',
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
        'winner': 'seeker',
      }).eq('id', widget.surpriseId);
      ref.invalidate(surprisesListProvider);

      if (mounted) {
        setState(() {
          _futureRewrite = rewrite;
          _loading = false;
        });
        _confettiController.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        showStars: true,
        glowColor: Colors.purple,
        child: Stack(
          children: [
            SafeArea(
              child: _loading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                              color: Colors.purple),
                          const SizedBox(height: 16),
                          Text(
                            'The judge is remembering...',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.homeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Text(
                            'Failed to open letter: $_error',
                            style: GoogleFonts.inter(
                                color: AppTheme.homeTextSecondary),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Icon(Icons.arrow_back_ios_rounded,
                                      color: Colors.white, size: 22),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'A Letter from the Future',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.homeTextPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // Original letter
                              _LetterCard(
                                title: 'What they wrote',
                                content: _originalLetter ?? '',
                                color: AppTheme.primaryOrange,
                              ),
                              const SizedBox(height: 24),

                              // Aged judge intro
                              Text(
                                '"I\'ve been holding this for you.\nThey wrote it when you were both still figuring things out.\nRead it slowly."',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.purple.shade200,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Future rewrite
                              _LetterCard(
                                title: 'The judge, 20 years wiser',
                                content: _futureRewrite ?? '',
                                color: Colors.purple,
                              ),
                              const SizedBox(height: 40),

                              // Back button
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusPill),
                                    color: Colors.purple,
                                  ),
                                  child: Text(
                                    'Back to Vault',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
            ),
            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                colors: [
                  Colors.purple,
                  Colors.pink,
                  Colors.deepPurple,
                  Colors.white,
                ],
                numberOfParticles: 25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({
    required this.title,
    required this.content,
    required this.color,
  });

  final String title;
  final String content;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppTheme.homeTextPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
