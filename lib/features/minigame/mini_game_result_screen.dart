import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/features/home/home_screen.dart';
import 'package:winkidoo/providers/mini_game_provider.dart';

class MiniGameResultScreen extends ConsumerStatefulWidget {
  const MiniGameResultScreen({super.key});

  @override
  ConsumerState<MiniGameResultScreen> createState() =>
      _MiniGameResultScreenState();
}

class _MiniGameResultScreenState extends ConsumerState<MiniGameResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scoreAnim = CurvedAnimation(
      parent: _scoreAnimController,
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _scoreAnimController.forward();
    });
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _scoreAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(miniGameProvider).value;
    final game = gameState?.game;

    if (game == null || !game.isGraded) {
      return Scaffold(
        body: CosmicBackground(
          glowColor: AppTheme.secondaryViolet,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                    color: AppTheme.secondaryViolet),
                const SizedBox(height: 16),
                Text(
                  'Loading result...',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final brightness = Theme.of(context).brightness;
    final score = game.gradeScore ?? 0;
    final commentary = game.gradeCommentary ?? '';
    final emoji = game.gradeEmoji ?? '✨';
    final personaName = HomeScreen.personaDisplayName(game.judgePersona);

    return Scaffold(
      body: CosmicBackground(
        showStars: true,
        glowColor: AppTheme.secondaryViolet,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppTheme.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(height: 12),

                Text(emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 8),

                Text(
                  game.gameTypeDisplayName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondaryViolet,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Judged by $personaName',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),

                // Animated score
                AnimatedBuilder(
                  animation: _scoreAnim,
                  builder: (context, _) {
                    final displayScore =
                        (_scoreAnim.value * score).round();
                    return Column(
                      children: [
                        Text(
                          '$displayScore',
                          style: GoogleFonts.inter(
                            fontSize: 72,
                            fontWeight: FontWeight.w800,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  Color(0xFF9B7DFF),
                                  Color(0xFF7C5CFC),
                                ],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 120, 80)),
                          ),
                        ),
                        Text(
                          'out of 100',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Commentary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: brightness == Brightness.dark
                        ? AppTheme.surface2
                        : AppTheme.lightSurfaceElevated,
                    border: Border.all(
                      color: AppTheme.secondaryViolet.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$personaName says:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondaryViolet,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        commentary,
                        style: GoogleFonts.caveat(
                          fontSize: 20,
                          color: brightness == Brightness.dark
                              ? AppTheme.textPrimary
                              : AppTheme.lightTextPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // The prompt reminder
                Text(
                  'The game was:',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  game.gamePrompt,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Back to home
                TextButton(
                  onPressed: () => context.go('/shell/home'),
                  child: Text(
                    'Back to Home',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
