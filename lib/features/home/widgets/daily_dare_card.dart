import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/home/home_screen.dart';
import 'package:winkidoo/providers/daily_dare_provider.dart';

class DailyDareCard extends ConsumerStatefulWidget {
  const DailyDareCard({
    super.key,
    required this.onTakeDare,
    required this.onViewResult,
    this.height,
    this.compact = false,
  });

  final VoidCallback onTakeDare;
  final VoidCallback onViewResult;
  final double? height;
  final bool compact;

  @override
  ConsumerState<DailyDareCard> createState() => _DailyDareCardState();
}

class _DailyDareCardState extends ConsumerState<DailyDareCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
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
    final targetHeight = widget.height ?? (widget.compact ? 176 : 196);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: AppTheme.microDuration,
        curve: AppTheme.standardCurve,
        transform:
            Matrix4.translationValues(0.0, _hovered ? -1.5 : 0.0, 0.0),
        constraints: BoxConstraints(minHeight: targetHeight),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.vaultHeroGradient(brightness),
          ),
          border: Border.all(color: AppTheme.premiumBorder30(brightness)),
          boxShadow: AppTheme.elevation3(brightness),
        ),
        child: Stack(
          children: [
            // Subtle glow from bottom (matches BattleCard)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppTheme.homeGlowPink.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Left vignette for depth (matches BattleCard)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppTheme.vaultDramaVignette.withValues(
                          alpha:
                              brightness == Brightness.dark ? 0.36 : 0.16,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  18, widget.compact ? 14 : 18, 18, widget.compact ? 14 : 18),
              child: Row(
                children: [
                  Expanded(
                    flex: 11,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Overline: category label (matches JudgeSpotlightCard)
                        Text(
                          _overlineForPhase(dareState.phase),
                          style: AppTheme.overline(brightness).copyWith(
                            color: AppTheme.homeTextSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Title
                        if (dareState.phase == DarePhase.graded) ...[
                          _GradedTitle(dare: dare, compact: widget.compact),
                        ] else ...[
                          Text(
                            personaName,
                            style: GoogleFonts.inter(
                              fontSize: widget.compact ? 19 : 21,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: AppTheme.homeTextPrimary,
                              height: 1.15,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        // Description / dare text
                        if (dareState.phase == DarePhase.graded) ...[
                          Text(
                            dare.gradeRoast ?? dare.gradeCommentary ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: widget.compact ? 13 : 14,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.homeTextSecondary,
                              height: 1.35,
                            ),
                          ),
                        ] else ...[
                          Text(
                            dare.dareText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: widget.compact ? 13 : 14,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.homeTextSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                        SizedBox(height: widget.compact ? 12 : 14),
                        // CTA
                        _buildCta(context, dareState, brightness),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 9,
                    child: _DareIconBlock(
                      phase: dareState.phase,
                      score: dare.gradeScore,
                      emoji: dare.gradeEmoji,
                      compact: widget.compact,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _overlineForPhase(DarePhase phase) {
    return switch (phase) {
      DarePhase.graded => 'DARE GRADED',
      DarePhase.myTurn => 'YOUR TURN',
      DarePhase.waitingForPartner => 'WAITING',
      DarePhase.grading => 'GRADING...',
      DarePhase.expired => 'EXPIRED',
      _ => 'DAILY DARE',
    };
  }

  Widget _buildCta(
    BuildContext context,
    DailyDareState dareState,
    Brightness brightness,
  ) {
    switch (dareState.phase) {
      case DarePhase.pending:
        return _DareActionButton(
          label: 'Take the Dare',
          icon: Icons.local_fire_department_rounded,
          onTap: widget.onTakeDare,
          compact: widget.compact,
        );
      case DarePhase.myTurn:
        return _DareActionButton(
          label: 'Your Turn!',
          icon: Icons.flash_on_rounded,
          onTap: widget.onTakeDare,
          compact: widget.compact,
        );
      case DarePhase.waitingForPartner:
        return _DareOutlineButton(
          label: 'Waiting for partner...',
          hovered: _hovered,
          compact: widget.compact,
        );
      case DarePhase.grading:
        return Row(
          mainAxisSize: MainAxisSize.min,
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
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.homeTextSecondary,
              ),
            ),
          ],
        );
      case DarePhase.graded:
        return _DareActionButton(
          label: 'View Result',
          icon: Icons.emoji_events_rounded,
          onTap: widget.onViewResult,
          compact: widget.compact,
        );
      case DarePhase.expired:
        return Text(
          'New dare tomorrow!',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppTheme.homeTextSecondary,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Graded title: score + persona name ──

class _GradedTitle extends StatelessWidget {
  const _GradedTitle({required this.dare, this.compact = false});

  final dynamic dare;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final score = dare.gradeScore ?? 0;
    final personaName = HomeScreen.personaDisplayName(dare.judgePersona);
    return Row(
      children: [
        Text(
          '$score/100',
          style: GoogleFonts.inter(
            fontSize: compact ? 19 : 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppTheme.primaryOrangeLight,
            height: 1.15,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '— $personaName',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              color: AppTheme.homeTextPrimary,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Right icon block (matches _MinimalBattleIconBlock pattern) ──

class _DareIconBlock extends StatelessWidget {
  const _DareIconBlock({
    required this.phase,
    this.score,
    this.emoji,
    this.compact = false,
  });

  final DarePhase phase;
  final int? score;
  final String? emoji;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: compact ? 100 : 118,
        height: compact ? 100 : 118,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: brightness == Brightness.dark
              ? AppTheme.glassFill
              : const Color(0x0A000000),
          border: Border.all(
            color: brightness == Brightness.dark
                ? AppTheme.glassBorderSubtle
                : const Color(0x14000000),
          ),
        ),
        child: Center(
          child: phase == DarePhase.graded && score != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (emoji != null)
                      Text(emoji!, style: const TextStyle(fontSize: 28)),
                    Text(
                      '$score',
                      style: GoogleFonts.inter(
                        fontSize: compact ? 28 : 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryOrangeLight,
                      ),
                    ),
                  ],
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: brightness == Brightness.dark
                            ? AppTheme.glassFill
                            : const Color(0x0A000000),
                      ),
                    ),
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 32,
                      color: brightness == Brightness.dark
                          ? AppTheme.textMuted
                          : AppTheme.lightTextMuted,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Orange CTA button (matches _BattleActionButton pattern) ──

class _DareActionButton extends StatefulWidget {
  const _DareActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.compact,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_DareActionButton> createState() => _DareActionButtonState();
}

class _DareActionButtonState extends State<_DareActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: AppTheme.microDuration,
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 0.0,
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          final scale = 1.0 - (_pressController.value * 0.04);
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF8C42), Color(0xFFFF6200)],
            ),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.25), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6200).withValues(alpha: 0.40),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFFFF8C42).withValues(alpha: 0.30),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 18 : 20,
              vertical: widget.compact ? 10 : 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  color: const Color(0xFF4A2800),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: widget.compact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: const Color(0xFF4A2800),
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

// ── Outline button for waiting state (matches _OutlineButton pattern) ──

class _DareOutlineButton extends StatelessWidget {
  const _DareOutlineButton({
    required this.label,
    required this.hovered,
    required this.compact,
  });

  final String label;
  final bool hovered;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: brightness == Brightness.dark
              ? AppTheme.glassBorder
              : AppTheme.lightGlassBorder,
          width: 1,
        ),
        color: brightness == Brightness.dark
            ? AppTheme.glassFill
            : AppTheme.lightGlassFill,
        boxShadow: [
          if (hovered && kIsWeb)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 8,
            ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 16,
          vertical: compact ? 9 : 10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.success,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: AppTheme.homeTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
