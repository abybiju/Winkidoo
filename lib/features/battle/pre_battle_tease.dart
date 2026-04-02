import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/judge_asset_map.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/battle/widgets/roulette_wheel.dart';
import 'package:winkidoo/models/judge.dart';

/// Full-screen pre-battle moment: judge portrait, aura, lock pulse, taunt quote, "Begin Persuasion".
/// If [isRoulette] is true, shows a roulette wheel spin before the standard tease.
/// Call [onBegin] when user taps the button or after 1.5s auto-advance.
class PreBattleTease extends StatefulWidget {
  const PreBattleTease({
    super.key,
    required this.judge,
    required this.userGender,
    required this.surpriseId,
    required this.onBegin,
    this.isRoulette = false,
    this.onRouletteResult,
  });

  final Judge judge;
  final String userGender;
  final String surpriseId;
  final void Function() onBegin;
  final bool isRoulette;
  final void Function(String result)? onRouletteResult;

  @override
  State<PreBattleTease> createState() => _PreBattleTeaseState();
}

class _PreBattleTeaseState extends State<PreBattleTease>
    with TickerProviderStateMixin {
  late AnimationController _auraController;
  late AnimationController _lockPulseController;
  Timer? _autoAdvanceTimer;
  bool _hasBegun = false;
  late String _tauntQuote;
  bool _rouletteComplete = false;

  @override
  void initState() {
    super.initState();
    final quotes = widget.judge.previewQuotes;
    _tauntQuote = quotes.isEmpty
        ? 'The judge awaits.'
        : quotes[Random().nextInt(quotes.length)];

    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _lockPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Only auto-advance if NOT roulette (roulette needs spin first)
    if (!widget.isRoulette) {
      _autoAdvanceTimer = Timer(const Duration(milliseconds: 1500), () {
        _beginOnce();
      });
    }
  }

  void _beginOnce() {
    if (_hasBegun) return;
    _hasBegun = true;
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
    widget.onBegin();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _auraController.dispose();
    _lockPulseController.dispose();
    super.dispose();
  }

  void _onRouletteResult(String result) {
    setState(() => _rouletteComplete = true);
    widget.onRouletteResult?.call(result);
    // Auto-advance to battle after roulette result
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 1200), () {
      _beginOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show roulette wheel before the normal tease
    if (widget.isRoulette && !_rouletteComplete) {
      return Stack(
        children: [
          _TeaseAuraBackground(
            color: widget.judge.primaryColor,
            animation: _auraController,
          ),
          SafeArea(
            child: Center(
              child: RouletteWheel(onResult: _onRouletteResult),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        _TeaseAuraBackground(
          color: widget.judge.primaryColor,
          animation: _auraController,
        ),
        SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              _TeasePortrait(
                  judge: widget.judge, userGender: widget.userGender),
              const SizedBox(height: 16),
              _TeaseLockPulse(animation: _lockPulseController),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '"$_tauntQuote"',
                  style: GoogleFonts.caveat(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!kIsWeb) HapticFeedback.lightImpact();
                      _beginOnce();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.judge.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Begin Persuasion',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Minimal radial gradient with subtle animated shift (same feel as judge selection).
class _TeaseAuraBackground extends StatelessWidget {
  const _TeaseAuraBackground({
    required this.color,
    required this.animation,
  });

  final Color color;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final shift = 0.3 + 0.2 * animation.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(shift - 0.5, -0.3),
              radius: 1.2,
              colors: [
                color.withValues(alpha: 0.35),
                color.withValues(alpha: 0.15),
                Theme.of(context).scaffoldBackgroundColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Large centered judge portrait (placeholder circle + initial or avatar).
class _TeasePortrait extends StatelessWidget {
  const _TeasePortrait({required this.judge, required this.userGender});

  final Judge judge;
  final String userGender;

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = JudgeAssetResolver.resolveAvatarPath(
      judge: judge,
      userGender: userGender,
    );
    return SizedBox(
      height: 160,
      child: Center(
        child: resolvedAvatar.isNotEmpty
            ? Image.asset(
                resolvedAvatar,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    final initial = judge.name.isNotEmpty ? judge.name[0] : '?';
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: judge.primaryColor.withValues(alpha: 0.4),
        border: Border.all(
          color: judge.accentColor.withValues(alpha: 0.8),
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: judge.primaryColor,
          ),
        ),
      ),
    );
  }
}

/// Subtle pulsing lock icon (scale 1.0 → 1.15).
class _TeaseLockPulse extends StatelessWidget {
  const _TeaseLockPulse({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = 1.0 + 0.15 * animation.value;
        return Transform.scale(
          scale: scale,
          child: Icon(
            Icons.lock_outline,
            size: 32,
            color: AppTheme.textSecondary.withValues(alpha: 0.8),
          ),
        );
      },
    );
  }
}
