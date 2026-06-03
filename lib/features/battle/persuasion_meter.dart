import 'package:flutter/material.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

/// "Crack the lock" persuasion meter.
///
/// A single progress bar that fills toward a goal lock pinned at the right edge.
/// `progress = seekerScore / resistance` — and that ratio reaching 1 is the REAL
/// unlock condition (see battle_chat_screen `meterCrossed`), so what you see is
/// what wins. A stage word + percentage tells you exactly how close you are.
///
/// `pulseResistanceTrigger` → the lock "hardens" (creator reinforced the vault).
/// `flickerResistanceTrigger` → the fill flashes (resistance weakened by fatigue).
class PersuasionMeter extends StatefulWidget {
  const PersuasionMeter({
    super.key,
    required this.seekerScore,
    required this.resistanceScore,
    this.maxScore = AppConstants.seekerScoreMax,
    this.pulseResistanceTrigger = 0,
    this.flickerResistanceTrigger = 0,
    this.animationDuration = const Duration(milliseconds: 450),
    this.isResolved = false,
  });

  final int seekerScore;
  final int resistanceScore;
  final int maxScore;

  /// Increment to flag the lock hardening (e.g. when the vault is reinforced).
  final int pulseResistanceTrigger;

  /// Increment to flicker the fill (e.g. when fatigue weakens resistance).
  final int flickerResistanceTrigger;
  final Duration animationDuration;

  /// When true the battle is over — stop the feedback animations.
  final bool isResolved;

  @override
  State<PersuasionMeter> createState() => _PersuasionMeterState();
}

class _PersuasionMeterState extends State<PersuasionMeter>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController; // resistance reinforced
  late final Animation<double> _pulse;
  late final AnimationController _flickerController; // resistance weakened
  late final Animation<double> _flicker;
  int _lastPulseTrigger = -1;
  int _lastFlickerTrigger = -1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _pulse = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutBack),
    );
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _flicker = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flickerController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(PersuasionMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isResolved) {
      if (!oldWidget.isResolved) {
        _pulseController.stop();
        _flickerController.stop();
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
      _flickerController
          .forward(from: 0)
          .then((_) => _flickerController.reverse());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flickerController.dispose();
    super.dispose();
  }

  double get _progress {
    final r = widget.resistanceScore;
    if (r <= 0) return 1; // resistance exhausted = unlocked
    return (widget.seekerScore / r).clamp(0.0, 1.0);
  }

  String _stage(double p) {
    if (p >= 1) return 'Unlocked';
    if (p >= 0.85) return 'So close!';
    if (p >= 0.6) return 'Winning them over';
    if (p >= 0.35) return "They're listening";
    if (p >= 0.12) return 'Warming up';
    return 'Make your case';
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: _progress),
        duration: widget.animationDuration,
        curve: Curves.easeOutCubic,
        builder: (context, p, _) {
          final pct = (p * 100).round();
          final reached = p >= 0.999;
          final goalColor = reached ? AppTheme.warmOk : AppTheme.gold;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('PERSUASION', style: AppTheme.mono(brightness, size: 9.5)),
                  const Spacer(),
                  Text(
                    '${_stage(p)} · $pct%',
                    style: AppTheme.mono(
                      brightness,
                      size: 9.5,
                      color: reached ? AppTheme.warmOk : AppTheme.orangeHi,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  const h = 16.0;
                  const lockD = 28.0;
                  final trackW = (w - lockD).clamp(0.0, w);
                  final fillW = (trackW * p).clamp(0.0, trackW);
                  return SizedBox(
                    height: lockD,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Track
                        Positioned(
                          left: 0,
                          right: lockD,
                          top: (lockD - h) / 2,
                          child: Container(
                            height: h,
                            decoration: BoxDecoration(
                              color: AppTheme.glassFill,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppTheme.warmLine),
                            ),
                          ),
                        ),
                        // Persuasion fill
                        Positioned(
                          left: 0,
                          top: (lockD - h) / 2,
                          child: AnimatedBuilder(
                            animation: _flicker,
                            builder: (context, _) {
                              final sheen =
                                  (1 - (_flicker.value - 0.5).abs() * 2)
                                          .clamp(0.0, 1.0) *
                                      0.40;
                              return Container(
                                width: fillW < 2 ? 0 : fillW,
                                height: h,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: reached
                                        ? const [
                                            AppTheme.warmOk,
                                            AppTheme.warmOk
                                          ]
                                        : AppTheme.glossyButtonGradient,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (reached
                                              ? AppTheme.warmOk
                                              : AppTheme.primaryOrange)
                                          .withValues(alpha: 0.45),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                foregroundDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: Colors.white.withValues(alpha: sheen),
                                ),
                              );
                            },
                          ),
                        ),
                        // Leading-edge spark
                        if (fillW > 6 && !reached)
                          Positioned(
                            left: fillW - 6,
                            top: (lockD / 2) - 6,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.orangeHi,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.orangeHi.withValues(alpha: 0.8),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Goal lock (the finish line) — hardens on pulse, opens at 100%
                        Positioned(
                          right: 0,
                          top: 0,
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, child) =>
                                Transform.scale(scale: 1 + _pulse.value * 0.18, child: child),
                            child: Container(
                              width: lockD,
                              height: lockD,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: reached
                                    ? AppTheme.warmOk.withValues(alpha: 0.18)
                                    : AppTheme.glassFill,
                                border: Border.all(
                                  color: goalColor.withValues(alpha: 0.9),
                                  width: 1.5,
                                ),
                                boxShadow: reached
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.warmOk
                                              .withValues(alpha: 0.6),
                                          blurRadius: 14,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                reached
                                    ? Icons.lock_open_rounded
                                    : Icons.lock_rounded,
                                size: 15,
                                color: goalColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
