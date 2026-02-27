import 'package:flutter/material.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

/// Horizontal persuasion vs resistance meter. Persuasion fills from the left;
/// resistance is shown as a threshold (right side). Animates value changes and
/// supports one-shot pulse (resistance increased) and flicker (resistance weakened).
class PersuasionMeter extends StatefulWidget {
  const PersuasionMeter({
    super.key,
    required this.seekerScore,
    required this.resistanceScore,
    this.maxScore = AppConstants.seekerScoreMax,
    this.pulseResistanceTrigger = 0,
    this.flickerResistanceTrigger = 0,
    this.animationDuration = const Duration(milliseconds: 350),
    this.isResolved = false,
  });

  final int seekerScore;
  final int resistanceScore;
  final int maxScore;
  /// Increment to trigger a pulse on the resistance segment (e.g. when vault reinforced).
  final int pulseResistanceTrigger;
  /// Increment to trigger a flicker on the resistance segment (e.g. when fatigue weakened).
  final int flickerResistanceTrigger;
  final Duration animationDuration;
  /// When true, resolution animation takes precedence: no pulse/flicker, and animation state resets.
  final bool isResolved;

  @override
  State<PersuasionMeter> createState() => _PersuasionMeterState();
}

class _PersuasionMeterState extends State<PersuasionMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late AnimationController _flickerController;
  late Animation<double> _flickerOpacity;
  int _lastPulseTrigger = -1;
  int _lastFlickerTrigger = -1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseScale = Tween<double>(begin: 1, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flickerOpacity = Tween<double>(begin: 1, end: 0.5)
        .animate(CurvedAnimation(parent: _flickerController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(PersuasionMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isResolved) {
      if (!oldWidget.isResolved) {
        _pulseController.stop();
        _flickerController.stop();
        _pulseController.reset();
        _flickerController.reset();
      }
      return;
    }
    if (widget.pulseResistanceTrigger != _lastPulseTrigger &&
        widget.pulseResistanceTrigger > 0) {
      _lastPulseTrigger = widget.pulseResistanceTrigger;
      _pulseController.forward(from: 0).then((_) => _pulseController.reverse());
    }
    if (widget.flickerResistanceTrigger != _lastFlickerTrigger &&
        widget.flickerResistanceTrigger > 0) {
      _lastFlickerTrigger = widget.flickerResistanceTrigger;
      _flickerController.forward(from: 0).then((_) => _flickerController.reverse());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.maxScore <= 0 ? 1 : widget.maxScore.toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: widget.seekerScore.clamp(0, widget.maxScore).toDouble(),
                ),
                duration: widget.animationDuration,
                curve: Curves.easeInOut,
                builder: (context, animSeeker, _) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: widget.resistanceScore.clamp(0, widget.maxScore).toDouble(),
                    ),
                    duration: widget.animationDuration,
                    curve: Curves.easeInOut,
                    builder: (context, animResistance, _) {
                      final persuasionWidth = w * (animSeeker / max).clamp(0.0, 1.0);
                      final resistancePos = w * (animResistance / max).clamp(0.0, 1.0);
                      return SizedBox(
                        height: 10,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Background track
                            Container(
                              width: w,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppTheme.surface.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            // Persuasion fill (left)
                            SizedBox(
                              width: (w * (animSeeker / max)).clamp(0.0, w),
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            // Resistance segment (from threshold to end) with pulse/flicker
                            Positioned(
                              left: resistancePos,
                              right: 0,
                              child: AnimatedBuilder(
                                animation: Listenable.merge([_pulseController, _flickerController]),
                                builder: (context, child) {
                                  return Transform.scale(
                                    alignment: Alignment.centerLeft,
                                    scale: _pulseScale.value,
                                    child: Opacity(
                                      opacity: _flickerOpacity.value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary.withValues(alpha: 0.6),
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(5),
                                      bottomRight: Radius.circular(5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Resistance threshold line (optional visual)
                            if (resistancePos > 0 && resistancePos < w)
                              Positioned(
                                left: resistancePos - 1,
                                top: -1,
                                bottom: -1,
                                child: Container(
                                  width: 2,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

