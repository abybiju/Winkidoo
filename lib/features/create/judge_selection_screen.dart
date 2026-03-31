import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/judge_asset_map.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/custom_judge.dart';
import 'package:winkidoo/models/judge.dart';
import 'package:winkidoo/providers/custom_judge_provider.dart';
import 'package:winkidoo/providers/judges_provider.dart';
import 'package:winkidoo/providers/user_profile_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/services/battle_sound_service.dart';

/// Cinematic judge selection: swipeable cards, animated aura, difficulty/chaos meters,
/// tone tags, rotating quotes. Fetches active judges from DB. Call [onSelect] with personaId and difficulty when user taps CTA.
class JudgeSelectionScreen extends ConsumerWidget {
  const JudgeSelectionScreen({
    super.key,
    required this.isJudgeLocked,
    required this.onSelect,
    this.onSelectCustom,
  });

  final bool Function(String personaId) isJudgeLocked;
  final void Function(String personaId, int difficulty) onSelect;
  /// Called when a custom judge is selected. Pass the custom judge ID + difficulty.
  final void Function(String customJudgeId, int difficulty)? onSelectCustom;

  /// Converts a CustomJudge into a Judge for display in the carousel.
  static Judge _customToJudge(CustomJudge custom) {
    final moods = custom.mood.split('+');
    final moodLabel = moods.map((m) => m[0].toUpperCase() + m.substring(1)).join(' + ');
    return Judge(
      id: 'custom_${custom.id}',
      personaId: 'custom_${custom.id}',
      name: custom.personalityName,
      tagline: '$moodLabel  •  Custom',
      difficultyLevel: custom.difficultyLevel,
      chaosLevel: custom.chaosLevel,
      previewQuotes: custom.previewQuotes,
      avatarAssetPath: custom.avatarStoragePath,
      premiumFlag: false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncJudges = ref.watch(activeJudgesProvider);
    final customJudgesAsync = ref.watch(availableCustomJudgesProvider);

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
        final customJudges = customJudgesAsync.value ?? [];

        // Merge: standard judges + custom judges converted to Judge objects
        final allJudges = [
          ...judges,
          ...customJudges.map(_customToJudge),
        ];

        if (allJudges.isEmpty) {
          return Center(
            child: Text(
              'No judges right now',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          );
        }
        return _JudgeSelectionContent(
          judges: allJudges,
          userGender: userGender,
          isJudgeLocked: (personaId) {
            // Custom judges are never locked
            if (personaId.startsWith('custom_')) return false;
            return isJudgeLocked(personaId);
          },
          onSelect: (personaId, difficulty) {
            if (personaId.startsWith('custom_') && onSelectCustom != null) {
              final customId = personaId.replaceFirst('custom_', '');
              onSelectCustom!(customId, difficulty);
            } else {
              onSelect(personaId, difficulty);
            }
          },
        );
      },
    );
  }
}

class _JudgeSelectionContent extends ConsumerStatefulWidget {
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
  ConsumerState<_JudgeSelectionContent> createState() => _JudgeSelectionContentState();
}

class _JudgeSelectionContentState extends ConsumerState<_JudgeSelectionContent>
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
  // Cache signed URL futures for custom judges to prevent blink on rebuild
  final Map<String, Future<String>> _signedUrlCache = {};

  Future<String>? _getCachedSignedUrl(Judge judge) {
    if (!judge.personaId.startsWith('custom_')) return null;
    final rawPath = judge.avatarAssetPath;
    if (rawPath == null || rawPath.isEmpty) return null;
    return _signedUrlCache.putIfAbsent(judge.personaId, () {
      return JudgePortrait._resolveSignedUrl(rawPath);
    });
  }

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
                    final j = widget.judges[index];
                    final isCustom = j.personaId.startsWith('custom_');
                    return Stack(
                      children: [
                        _JudgeCard(
                          judge: j,
                          userGender: widget.userGender,
                          portraitFloat: _portraitFloatController,
                          quoteIndex: index == _currentIndex ? _quoteIndex : 0,
                          sealingProgress:
                              index == _currentIndex ? sealingProgress : 0.0,
                          cachedAvatarFuture: _getCachedSignedUrl(j),
                        ),
                        if (isCustom)
                          Positioned(
                            top: 12,
                            left: 28,
                            child: GestureDetector(
                              onTap: () async {
                                final customId = j.personaId.replaceFirst('custom_', '');
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppTheme.surface2,
                                    title: Text('Remove ${j.name}?',
                                        style: GoogleFonts.inter(
                                            color: AppTheme.homeTextPrimary)),
                                    content: Text(
                                        'This will remove the judge from your battle lineup.',
                                        style: GoogleFonts.inter(
                                            color: AppTheme.homeTextSecondary)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: Text('Cancel',
                                            style: GoogleFonts.inter(
                                                color: AppTheme.textMuted)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: Text('Remove',
                                            style: GoogleFonts.inter(
                                                color: AppTheme.error)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;
                                final client = Supabase.instance.client;
                                await client
                                    .from('custom_judges')
                                    .update({'is_active_for_battle': false})
                                    .eq('id', customId);
                                debugPrint('Battlefield: removed judge $customId from battle');
                                ref.invalidate(myCustomJudgesProvider);
                                ref.invalidate(availableCustomJudgesProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${j.name} removed from battle'),
                                      backgroundColor: AppTheme.textMuted,
                                    ),
                                  );
                                  context.pop();
                                }
                              },
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.6),
                                  border: Border.all(
                                      color: AppTheme.error.withValues(alpha: 0.6)),
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 16, color: AppTheme.error),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: SelectJudgeButton(
                  judge: judge,
                  locked: locked,
                  sealing: _isSealing,
                  onPressed: () => _onSealWithJudge(judge),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/shell/create-judge'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1B22),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFFFABC4E)),
                            const SizedBox(width: 6),
                            Text('Custom Judge',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFFABC4E))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => context.push('/shell/judge-marketplace'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1B22),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.explore_rounded, size: 16, color: Color(0xFFCFC2D6)),
                            const SizedBox(width: 6),
                            Text('Marketplace',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFCFC2D6))),
                          ],
                        ),
                      ),
                    ),
                  ],
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
        final baseAlpha = 0.15 + 0.20 * sealingIntensity;
        final midAlpha = 0.05 + 0.15 * sealingIntensity;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF05050A),
            gradient: RadialGradient(
              center: Alignment(shift - 0.5, -0.3),
              radius: 1.5,
              colors: [
                color.withValues(alpha: baseAlpha.clamp(0.0, 1.0)),
                color.withValues(alpha: midAlpha.clamp(0.0, 1.0)),
                const Color(0xFF05050A),
              ],
              stops: const [0.0, 0.4, 1.0],
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
    this.cachedAvatarFuture,
  });

  final Judge judge;
  final String userGender;
  final Animation<double> portraitFloat;
  final int quoteIndex;
  final double sealingProgress;
  final Future<String>? cachedAvatarFuture;

  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              JudgePortrait(
                judge: judge,
                userGender: userGender,
                floatAnimation: portraitFloat,
                sealingProgress: sealingProgress,
                cachedAvatarFuture: cachedAvatarFuture,
              ),
              Positioned(
                top: 8,
                left: 8,
                child: _NewBadge(judge: judge),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _SeasonalBadge(judge: judge),
              ),
            ],
          ),
          const SizedBox(height: 20),
          JudgeMetaInfo(judge: judge),
          const SizedBox(height: 16),
          DifficultyMeter(level: judge.difficultyLevel),
          const SizedBox(height: 16),
          ChaosMeter(level: judge.chaosLevel),
          const SizedBox(height: 16),
          ToneTags(tags: judge.toneTags),
          const SizedBox(height: 24),
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
    this.cachedAvatarFuture,
  });

  final Judge judge;
  final String userGender;
  final Animation<double> floatAnimation;
  final double sealingProgress;
  final Future<String>? cachedAvatarFuture;

  /// Resolves a signed URL from either "bucket:path" (new) or plain path (old/surprises).
  static Future<String> _resolveSignedUrl(String rawPath) {
    final String bucket;
    final String path;
    if (rawPath.contains(':')) {
      bucket = rawPath.split(':').first;
      path = rawPath.split(':').skip(1).join(':');
    } else {
      bucket = 'surprises';
      path = rawPath;
    }
    return Supabase.instance.client.storage
        .from(bucket)
        .createSignedUrl(path, 3600);
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = judge.personaId.startsWith('custom_');
    final resolvedAvatar = isCustom
        ? '' // Custom judges use network image, not asset
        : JudgeAssetResolver.resolveAvatarPath(
            judge: judge,
            userGender: userGender,
          );
    final customStoragePath = isCustom ? (judge.avatarAssetPath ?? '') : '';
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
      child: Container(
        height: 270,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: const Color(0xFF1B1B22).withValues(alpha: 0.6),
          boxShadow: [
            BoxShadow(
              color: judge.primaryColor.withValues(alpha: 0.1),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: const SizedBox(),
              ),
            ),
            Positioned.fill(
              child: isCustom && customStoragePath.isNotEmpty
                  ? FutureBuilder<String>(
                      future: cachedAvatarFuture ?? _resolveSignedUrl(customStoragePath),
                      builder: (ctx, snap) {
                        if (!snap.hasData) return _placeholder(judge);
                        return Image.network(
                          snap.data!,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (_, __, ___) => _placeholder(judge),
                        );
                      },
                    )
                  : resolvedAvatar.isNotEmpty
                      ? Image.asset(
                          resolvedAvatar,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (_, __, ___) => _placeholder(judge),
                        )
                      : _placeholder(judge),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      judge.primaryColor.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(Judge judge) {
    final initial = judge.name.isNotEmpty ? judge.name[0] : '?';
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: judge.primaryColor.withValues(alpha: 0.4),
        ),
        child: Center(
          child: Text(
            initial,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: judge.primaryColor,
            ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          judge.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            color: Colors.white,
          ),
          textAlign: TextAlign.left,
        ),
        if (judge.tagline != null && judge.tagline!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            judge.tagline!,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFFCFC2D6),
            ),
            textAlign: TextAlign.left,
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
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'DIFFICULTY',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: const Color(0xFF988D9F),
          ),
        ),
        const SizedBox(width: 12),
        ...List.generate(5, (i) {
          final active = i < level;
          return Container(
            margin: const EdgeInsets.only(right: 6),
            width: 16,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: active ? const Color(0xFFFABC4E) : const Color(0xFF35343B),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFABC4E).withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CHAOS LEVEL',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: const Color(0xFF988D9F),
                ),
              ),
              if (isHighChaos)
                const Text('⚡', style: TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth *
                  (widget.level / 5).clamp(0.0, 1.0);
              return SizedBox(
                height: 12,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (w > 0)
                      Positioned(
                        left: 0,
                        top: 5,
                        width: w,
                        height: 2,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0x0006B6D4), Color(0xFF06B6D4)],
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: w > 12 ? w - 12 : 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF06B6D4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF06B6D4).withValues(alpha: 0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
      alignment: WrapAlignment.start,
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map((t) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B22),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                child: Text(
                  t,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFE4E1EA),
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
      child: ClipRRect(
        key: ValueKey(quote),
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF35343B).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Text(
              '"$quote"',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.90),
              ),
              textAlign: TextAlign.center,
            ),
          ),
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
    return AnimatedScale(
      scale: sealing ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutExpo,
      child: GestureDetector(
        onTap: disabled ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            gradient: LinearGradient(
              colors: [
                judge.primaryColor,
                judge.primaryColor.withValues(alpha: sealing ? 1.0 : 0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: judge.primaryColor.withValues(alpha: sealing ? 0.8 : 0.4),
                blurRadius: sealing ? 30 : 20,
                spreadRadius: sealing ? 4 : 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (locked) ...[
                const Icon(Icons.lock, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Wink+ required',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ] else if (sealing) ...[
                const SizedBox(
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
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ] else ...[
                Text(
                  'Seal with This Judge',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
