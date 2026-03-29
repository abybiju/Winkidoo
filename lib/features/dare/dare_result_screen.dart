import 'dart:ui' as ui;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/confetti_overlay.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/features/home/home_screen.dart';
import 'package:winkidoo/models/daily_dare.dart';
import 'package:winkidoo/providers/daily_dare_provider.dart';

class DareResultScreen extends ConsumerStatefulWidget {
  const DareResultScreen({super.key});

  @override
  ConsumerState<DareResultScreen> createState() => _DareResultScreenState();
}

class _DareResultScreenState extends ConsumerState<DareResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnim;
  late ConfettiController _confettiController;
  final _shareCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scoreAnim = CurvedAnimation(
      parent: _scoreAnimController,
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _scoreAnimController.forward();
        _confettiController.play();
      }
    });
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _scoreAnimController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _shareCard(DailyDare dare) async {
    try {
      final boundary = _shareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final personaName =
          HomeScreen.personaDisplayName(dare.judgePersona);
      final score = dare.gradeScore ?? 0;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png', name: 'dare_card.png')],
          text:
              'We scored $score/100 on today\'s dare from $personaName! Can you beat us? #Winkidoo',
        ),
      );
    } catch (e) {
      debugPrint('Share dare card error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dareState = ref.watch(dailyDareProvider).value;
    final dare = dareState?.dare;

    if (dare == null || !dare.isGraded) {
      return Scaffold(
        body: CosmicBackground(
          glowColor: AppTheme.primaryOrange,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                    color: AppTheme.primaryOrange),
                const SizedBox(height: 16),
                Text(
                  'Loading result...',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final brightness = Theme.of(context).brightness;
    final score = dare.gradeScore ?? 0;
    final commentary = dare.gradeCommentary ?? '';
    final emoji = dare.gradeEmoji ?? '✨';
    final personaName =
        HomeScreen.personaDisplayName(dare.judgePersona);

    return Scaffold(
      body: Stack(
        children: [
          CosmicBackground(
            showStars: true,
            glowColor: AppTheme.primaryOrange,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  children: [
                    // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppTheme.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(height: 12),

                // Judge emoji
                Text(emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 8),

                // Persona name
                Text(
                  personaName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textOrangeAccent,
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
                          style: GoogleFonts.poppins(
                            fontSize: 72,
                            fontWeight: FontWeight.w800,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  AppTheme.battleGradientA,
                                  AppTheme.battleGradientB,
                                ],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 120, 80)),
                          ),
                        ),
                        Text(
                          'out of 100',
                          style: GoogleFonts.poppins(
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
                      color: AppTheme.glassBorderOrange,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$personaName says:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textOrangeAccent,
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

                // The dare (reminder)
                Text(
                  'The dare was:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dare.dareText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Hidden share card for screenshot
                Offstage(
                  child: RepaintBoundary(
                    key: _shareCardKey,
                    child: _DareShareCard(dare: dare),
                  ),
                ),

                // Share CTA
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        colors: [AppTheme.ctaOrangeA, AppTheme.ctaOrangeB],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppTheme.ctaOuterGlow.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: MaterialButton(
                      onPressed: () => _shareCard(dare),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.share_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Share Dare Card',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

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
          ConfettiOverlay(controller: _confettiController),
        ],
      ),
    );
  }
}

/// The share card rendered as an image via RepaintBoundary.
class _DareShareCard extends StatelessWidget {
  const _DareShareCard({required this.dare});

  final DailyDare dare;

  @override
  Widget build(BuildContext context) {
    final score = dare.gradeScore ?? 0;
    final roast = dare.gradeRoast ?? dare.gradeCommentary ?? '';
    final personaName =
        HomeScreen.personaDisplayName(dare.judgePersona);
    final emoji = dare.gradeEmoji ?? '✨';

    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1030), Color(0xFF2A1048)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryOrange.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              'DAILY DARE',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppTheme.primaryOrangeLight,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Persona + emoji
          Text(
            '$emoji $personaName',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textOrangeAccent,
            ),
          ),
          const SizedBox(height: 16),

          // Dare text
          Text(
            dare.dareText,
            textAlign: TextAlign.center,
            style: GoogleFonts.caveat(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Score
          Text(
            '$score',
            style: GoogleFonts.poppins(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: AppTheme.battleGradientA,
            ),
          ),
          Text(
            'out of 100',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),

          // Roast quote
          Text(
            '"$roast"',
            textAlign: TextAlign.center,
            style: GoogleFonts.caveat(
              fontSize: 17,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Branding
          Text(
            'Winkidoo  •  Daily Love Dares',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
