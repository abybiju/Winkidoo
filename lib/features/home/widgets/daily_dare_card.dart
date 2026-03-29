import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/home/home_screen.dart';
import 'package:winkidoo/providers/daily_dare_provider.dart';

class DailyDareCard extends ConsumerWidget {
  const DailyDareCard({
    super.key,
    required this.onTakeDare,
    required this.onViewResult,
    this.compact = false,
  });

  final VoidCallback onTakeDare;
  final VoidCallback onViewResult;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dareAsync = ref.watch(dailyDareProvider);

    return dareAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (dareState) {
        if (dareState.phase == DarePhase.unavailable ||
            dareState.phase == DarePhase.loading ||
            dareState.phase == DarePhase.error) {
          return const SizedBox.shrink();
        }
        return _buildCard(context, dareState);
      },
    );
  }

  Widget _buildCard(BuildContext context, DailyDareState dareState) {
    final brightness = Theme.of(context).brightness;
    final dare = dareState.dare;
    if (dare == null) return const SizedBox.shrink();

    final personaName = HomeScreen.personaDisplayName(dare.judgePersona);

    return Container(
      constraints: BoxConstraints(minHeight: compact ? 130 : 148),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientForPhase(dareState.phase, brightness),
        ),
        border: Border.all(
          color: _borderForPhase(dareState.phase, brightness),
        ),
        boxShadow: AppTheme.elevation3(brightness),
      ),
      child: Stack(
        children: [
          // Warm orange glow from top-right
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.2,
                    colors: [
                      AppTheme.primaryOrange.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: badge + persona
                Row(
                  children: [
                    _DareBadge(phase: dareState.phase),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        personaName,
                        style: GoogleFonts.poppins(
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textOrangeAccent,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (dare.gradeEmoji != null)
                      Text(
                        dare.gradeEmoji!,
                        style: const TextStyle(fontSize: 20),
                      ),
                  ],
                ),
                SizedBox(height: compact ? 8 : 10),
                // Dare text or result
                if (dareState.phase == DarePhase.graded) ...[
                  _GradedContent(dare: dare, compact: compact),
                ] else ...[
                  Text(
                    dare.dareText,
                    style: GoogleFonts.caveat(
                      fontSize: compact ? 17 : 19,
                      fontWeight: FontWeight.w600,
                      color: brightness == Brightness.dark
                          ? AppTheme.textPrimary
                          : AppTheme.lightTextPrimary,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: compact ? 10 : 14),
                // CTA row
                _buildCta(context, dareState, brightness),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCta(
    BuildContext context,
    DailyDareState dareState,
    Brightness brightness,
  ) {
    switch (dareState.phase) {
      case DarePhase.pending:
        return _OrangePillCta(
          label: 'Take the Dare',
          onTap: onTakeDare,
        );
      case DarePhase.myTurn:
        return _OrangePillCta(
          label: 'Your Turn!',
          onTap: onTakeDare,
          pulsing: true,
        );
      case DarePhase.waitingForPartner:
        return Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 18),
            const SizedBox(width: 6),
            Text(
              'Waiting for partner...',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        );
      case DarePhase.grading:
        return Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Judge is grading...',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        );
      case DarePhase.graded:
        return _OrangePillCta(
          label: 'View Result',
          onTap: onViewResult,
        );
      case DarePhase.expired:
        return Text(
          'New dare tomorrow!',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  List<Color> _gradientForPhase(DarePhase phase, Brightness brightness) {
    if (brightness == Brightness.light) {
      return [AppTheme.lightCardA, AppTheme.lightCardB];
    }
    if (phase == DarePhase.expired) {
      return [AppTheme.surface1, AppTheme.surface2];
    }
    return [AppTheme.spotlightGradientA, AppTheme.spotlightGradientB];
  }

  Color _borderForPhase(DarePhase phase, Brightness brightness) {
    if (phase == DarePhase.myTurn) return AppTheme.primaryOrange.withValues(alpha: 0.4);
    if (phase == DarePhase.graded) return AppTheme.premiumAmber.withValues(alpha: 0.3);
    return AppTheme.premiumBorder30(brightness);
  }
}

class _GradedContent extends StatelessWidget {
  const _GradedContent({required this.dare, this.compact = false});

  final dynamic dare;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final score = dare.gradeScore ?? 0;
    final commentary = dare.gradeRoast ?? dare.gradeCommentary ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score circle
        Container(
          width: compact ? 48 : 56,
          height: compact ? 48 : 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.battleGradientA, AppTheme.battleGradientB],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                blurRadius: 12,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$score',
            style: GoogleFonts.poppins(
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            commentary,
            style: GoogleFonts.caveat(
              fontSize: compact ? 15 : 17,
              color: brightness == Brightness.dark
                  ? AppTheme.textPrimary
                  : AppTheme.lightTextPrimary,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DareBadge extends StatelessWidget {
  const _DareBadge({required this.phase});

  final DarePhase phase;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (phase) {
      DarePhase.graded => ('GRADED', AppTheme.premiumAmber),
      DarePhase.myTurn => ('YOUR TURN', AppTheme.primaryOrange),
      DarePhase.expired => ('EXPIRED', AppTheme.textMuted),
      _ => ('DAILY DARE', AppTheme.primaryOrangeLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

class _OrangePillCta extends StatefulWidget {
  const _OrangePillCta({
    required this.label,
    required this.onTap,
    this.pulsing = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool pulsing;

  @override
  State<_OrangePillCta> createState() => _OrangePillCtaState();
}

class _OrangePillCtaState extends State<_OrangePillCta>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.pulsing) _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = widget.pulsing ? 1.0 + (_pulseController.value * 0.04) : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [AppTheme.ctaOrangeA, AppTheme.ctaOrangeB],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.ctaOuterGlow.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
