import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/judge_asset_map.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/judge.dart';
import 'package:winkidoo/providers/judges_provider.dart';
import 'package:winkidoo/providers/user_profile_provider.dart';
import 'package:winkidoo/services/battle_sound_service.dart';

/// Cinematic judge selection: swipeable cards, animated aura, difficulty/chaos meters,
/// tone tags, rotating quotes. Fetches active judges from DB. Call [onSelect] with personaId and difficulty when user taps CTA.
class JudgeSelectionScreen extends ConsumerWidget {
  const JudgeSelectionScreen({
    super.key,
    required this.isJudgeLocked,
    required this.onSelect,
  });

  final bool Function(String personaId) isJudgeLocked;
  final void Function(String personaId, int difficulty) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncJudges = ref.watch(activeJudgesProvider);
    return asyncJudges.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (_, __) => Center(
        child: Text(
          'Something went wrong',
          style: TextStyle(color: AppTheme.error),
        ),
      ),
      data: (judges) {
        final userGender = ref.watch(userProfileMetaProvider).gender;
        if (judges.isEmpty) {
          return Center(
            child: Text(
              'No judges right now',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          );
        }
        return _JudgeSelectionContent(
          judges: judges,
          userGender: userGender,
          isJudgeLocked: isJudgeLocked,
          onSelect: onSelect,
        );
      },
    );
  }
}

class _JudgeSelectionContent extends StatefulWidget {
  const _JudgeSelectionContent({
    required this.judges,
    required this.userGender,
    required this.isJudgeLocked,
    required this.onSelect,
  });

  final List<Judge> judges;
  final String userGender;
  final bool Function(String personaId) isJudgeLocked;
  final void Function(String personaId, int difficulty) onSelect;

  @override
  State<_JudgeSelectionContent> createState() => _JudgeSelectionContentState();
}

class _JudgeSelectionContentState extends State<_JudgeSelectionContent>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _auraController;
  late AnimationController _portraitFloatController;
  late AnimationController _sealingController;
  int _currentIndex = 0;
  int _quoteIndex = 0;
  Timer? _quoteTimer;
  bool _isSealing = false;
  BattleSoundService? _soundService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _soundService == null)
        _soundService = BattleSoundService();
    });
    _pageController = PageController();
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _portraitFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _sealingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _startQuoteTimer();
  }

  void _startQuoteTimer() {
    _quoteTimer?.cancel();
    _quoteTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final judge = widget.judges[_currentIndex];
      if (judge.previewQuotes.isEmpty) return;
      setState(() {
        _quoteIndex = (_quoteIndex + 1) % judge.previewQuotes.length;
      });
    });
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _soundService?.dispose();
    _pageController.dispose();
    _auraController.dispose();
    _portraitFloatController.dispose();
    _sealingController.dispose();
    super.dispose();
  }

  void _onSealingTick() {
    if (mounted) setState(() {});
  }

  void _onSealWithJudge(Judge judge) {
    if (widget.isJudgeLocked(judge.personaId) || _isSealing) return;
    if (!kIsWeb) HapticFeedback.lightImpact();
    setState(() => _isSealing = true);
    _soundService ??= BattleSoundService();
    _sealingController.addListener(_onSealingTick);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _isSealing) _soundService?.playLockClick();
    });
    _sealingController.forward().then((_) {
      _sealingController.removeListener(_onSealingTick);
      if (mounted) {
        widget.onSelect(judge.personaId, judge.difficultyLevel);
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _quoteIndex = 0;
    });
    _startQuoteTimer();
  }

  @override
  Widget build(BuildContext context) {
    final judge = widget.judges[_currentIndex];
    final locked = widget.isJudgeLocked(judge.personaId);
    final sealingProgress = _isSealing ? _sealingController.value : 0.0;

    return Stack(
      children: [
        AnimatedAuraBackground(
          color: judge.primaryColor,
          animation: _auraController,
          sealingIntensity: sealingProgress,
        ),
        SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: widget.judges.length,
                  itemBuilder: (context, index) {
                    return _JudgeCard(
                      judge: widget.judges[index],
                      userGender: widget.userGender,
                      portraitFloat: _portraitFloatController,
                      quoteIndex: index == _currentIndex ? _quoteIndex : 0,
                      sealingProgress:
                          index == _currentIndex ? sealingProgress : 0.0,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: SelectJudgeButton(
                  judge: judge,
                  locked: locked,
                  sealing: _isSealing,
                  onPressed: () => _onSealWithJudge(judge),
                ),
              ),
            ],
          ),
        ),
        if (_isSealing) _VaultSealedOverlay(progress: sealingProgress),
      ],
    );
  }
}

/// Full-screen soft radial gradient with subtle animated shift.
/// [sealingIntensity] 0..1 intensifies the gradient during vault-seal transition.
class AnimatedAuraBackground extends StatelessWidget {
  const AnimatedAuraBackground({
    super.key,
    required this.color,
    required this.animation,
    this.sealingIntensity = 0,
  });

  final Color color;
  final Animation<double> animation;
  final double sealingIntensity;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final shift = 0.3 + 0.2 * (animation.value);
        final baseAlpha = 0.35 + 0.25 * sealingIntensity;
        final midAlpha = 0.15 + 0.2 * sealingIntensity;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(shift - 0.5, -0.3),
              radius: 1.2,
              colors: [
                color.withValues(alpha: baseAlpha.clamp(0.0, 1.0)),
                color.withValues(alpha: midAlpha.clamp(0.0, 1.0)),
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

/// Centered overlay text "The vault is sealed." with fade-in during sealing transition.
/// Future: pass [Judge] and, for Chaos Gremlin (high chaosLevel), apply subtle text shake/distort.
class _VaultSealedOverlay extends StatelessWidget {
  const _VaultSealedOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final textOpacity = (progress * 2.5).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.2 * progress),
        alignment: Alignment.center,
        child: Opacity(
          opacity: textOpacity,
          child: Text(
            'The vault is sealed.',
            style: GoogleFonts.caveat(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _JudgeCard extends StatelessWidget {
  const _JudgeCard({
    required this.judge,
    required this.userGender,
    required this.portraitFloat,
    required this.quoteIndex,
    this.sealingProgress = 0,
  });

  final Judge judge;
  final String userGender;
  final Animation<double> portraitFloat;
  final int quoteIndex;
  final double sealingProgress;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              JudgePortrait(
                judge: judge,
                userGender: userGender,
                floatAnimation: portraitFloat,
                sealingProgress: sealingProgress,
              ),
              Positioned(
                top: 0,
                left: 0,
                child: _NewBadge(judge: judge),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: _SeasonalBadge(judge: judge),
              ),
            ],
          ),
          const SizedBox(height: 20),
          JudgeMetaInfo(judge: judge),
          const SizedBox(height: 16),
          DifficultyMeter(level: judge.difficultyLevel),
          const SizedBox(height: 12),
          ChaosMeter(level: judge.chaosLevel),
          const SizedBox(height: 16),
          ToneTags(tags: judge.toneTags),
          const SizedBox(height: 20),
          RotatingQuote(
            quote: judge.previewQuotes.isNotEmpty
                ? judge.previewQuotes[quoteIndex % judge.previewQuotes.length]
                : '',
          ),
        ],
      ),
    );
  }
}

/// "New" badge at top-left of portrait: show when judge is new, seasonal, and within 7 days of season start or creation.
class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.judge});

  final Judge judge;

  static const int _newDays = 7;

  @override
  Widget build(BuildContext context) {
    if (!judge.isNew || judge.seasonStart == null) {
      return const SizedBox.shrink();
    }
    final now = DateTime.now().toUtc();
    final withinSeason = judge.seasonStart != null &&
        now.difference(judge.seasonStart!.toUtc()).inDays <= _newDays;
    final withinCreated = judge.createdAt != null &&
        now.difference(judge.createdAt!.toUtc()).inDays <= _newDays;
    if (!withinSeason && !withinCreated) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: judge.primaryColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '✨ New',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Small badge at top-right of portrait: "Seasonal" / "Limited Time" or "Ends in X days" when near expiry.
class _SeasonalBadge extends StatelessWidget {
  const _SeasonalBadge({required this.judge});

  final Judge judge;

  static const int _daysNearExpiry = 3;

  @override
  Widget build(BuildContext context) {
    if (judge.seasonStart == null && judge.seasonEnd == null) {
      return const SizedBox.shrink();
    }
    final end = judge.seasonEnd;
    final now = DateTime.now().toUtc();
    String label;
    if (end != null) {
      final daysLeft = end.difference(now).inDays;
      if (daysLeft <= _daysNearExpiry && daysLeft >= 0) {
        label = daysLeft == 0
            ? 'Ends today'
            : daysLeft == 1
                ? 'Ends in 1 day'
                : 'Ends in $daysLeft days';
      } else if (judge.seasonStart != null) {
        label = 'Limited Time';
      } else {
        label = 'Limited Time';
      }
    } else {
      label = 'Seasonal';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: judge.primaryColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class JudgePortrait extends StatelessWidget {
  const JudgePortrait({
    super.key,
    required this.judge,
    required this.userGender,
    required this.floatAnimation,
    this.sealingProgress = 0,
  });

  final Judge judge;
  final String userGender;
  final Animation<double> floatAnimation;
  final double sealingProgress;

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = JudgeAssetResolver.resolveAvatarPath(
      judge: judge,
      userGender: userGender,
    );
    return AnimatedBuilder(
      animation: floatAnimation,
      builder: (context, child) {
        final floatScale = 1.0 + 0.02 * floatAnimation.value;
        final sealScale = 0.05 * sealingProgress;
        final scale = floatScale + sealScale;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: SizedBox(
        height: 160,
        child: Center(
          child: resolvedAvatar.isNotEmpty
              ? Image.asset(
                  resolvedAvatar,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _placeholder(judge),
                )
              : _placeholder(judge),
        ),
      ),
    );
  }

  Widget _placeholder(Judge judge) {
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

class JudgeMetaInfo extends StatelessWidget {
  const JudgeMetaInfo({super.key, required this.judge});

  final Judge judge;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          judge.name,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        if (judge.tagline != null && judge.tagline!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            judge.tagline!,
            style: GoogleFonts.caveat(
              fontSize: 18,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class DifficultyMeter extends StatelessWidget {
  const DifficultyMeter({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Difficulty: ',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        ...List.generate(5, (i) {
          return Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              i < level ? '🔥' : '○',
              style: const TextStyle(fontSize: 16),
            ),
          );
        }),
      ],
    );
  }
}

class ChaosMeter extends StatefulWidget {
  const ChaosMeter({super.key, required this.level});

  final int level;

  @override
  State<ChaosMeter> createState() => _ChaosMeterState();
}

class _ChaosMeterState extends State<ChaosMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _jitterController;

  @override
  void initState() {
    super.initState();
    _jitterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void didUpdateWidget(ChaosMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.level >= 4 && !_jitterController.isAnimating) {
      _jitterController.repeat(reverse: true);
    } else if (widget.level < 4) {
      _jitterController.stop();
      _jitterController.reset();
    }
  }

  @override
  void dispose() {
    _jitterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHighChaos = widget.level >= 4;
    if (isHighChaos && !_jitterController.isAnimating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _jitterController.repeat(reverse: true);
      });
    }
    return AnimatedBuilder(
      animation: _jitterController,
      builder: (context, child) {
        final offset =
            isHighChaos ? 2.0 * (_jitterController.value - 0.5) : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Chaos Level',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth *
                        (widget.level / 5).clamp(0.0, 1.0);
                    return Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: w,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (isHighChaos) ...[
                const SizedBox(width: 6),
                const Text('⚡', style: TextStyle(fontSize: 14)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ToneTags extends StatelessWidget {
  const ToneTags({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: tags
          .map((t) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  t,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class RotatingQuote extends StatelessWidget {
  const RotatingQuote({super.key, required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    if (quote.isEmpty) return const SizedBox.shrink();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(quote),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '"$quote"',
          style: GoogleFonts.caveat(
            fontSize: 20,
            fontStyle: FontStyle.italic,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class SelectJudgeButton extends StatelessWidget {
  const SelectJudgeButton({
    super.key,
    required this.judge,
    required this.locked,
    required this.onPressed,
    this.sealing = false,
  });

  final Judge judge;
  final bool locked;
  final VoidCallback onPressed;
  final bool sealing;

  @override
  Widget build(BuildContext context) {
    final disabled = locked || sealing;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: judge.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (locked) ...[
              const Icon(Icons.lock, size: 20),
              const SizedBox(width: 8),
              Text(
                'Wink+ required',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (sealing) ...[
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sealing...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              Text(
                'Seal with This Judge',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
