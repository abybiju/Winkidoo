import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/streak_provider.dart';

class WinkidooTopBar extends StatelessWidget {
  const WinkidooTopBar({
    super.key,
    this.title,
    this.showLogo = true,
    this.logoSize = 32,
    this.logoTextSize = 20,
    this.matchLogoToWordmark = false,
    this.notificationCount = 0,
    this.streakCount = 0,
    this.streakTier = StreakTier.none,
    this.levelCount = 0,
    this.onNotificationTap,
    this.onStreakTap,
    this.onProfileTap,
    this.trailing,
  });

  final String? title;
  final bool showLogo;
  final double logoSize;
  final double logoTextSize;
  final bool matchLogoToWordmark;
  final int notificationCount;
  final int streakCount;
  final StreakTier streakTier;
  final int levelCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onStreakTap;
  final VoidCallback? onProfileTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380;
    final computedLogoSize = matchLogoToWordmark
        ? (logoTextSize * 1.04).clamp(20.0, 44.0).toDouble()
        : logoSize;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppTheme.glassBlurSigma,
          sigmaY: AppTheme.glassBlurSigma,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12, vertical: 8),
          decoration: BoxDecoration(
            color: brightness == Brightness.dark
                ? AppTheme.glassFill
                : AppTheme.lightGlassFill,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: brightness == Brightness.dark
                  ? AppTheme.glassBorder
                  : AppTheme.lightGlassBorder,
            ),
            boxShadow: AppTheme.elevation1(brightness),
          ),
          child: Row(
            children: [
              if (showLogo)
                Row(
                  children: [
                    SizedBox(width: compact ? 4 : 6),
                    SizedBox(
                      height: compact ? 34 : 38,
                      width: compact ? 34 : 38,
                      child: Image.asset(
                        'assets/images/winkidoo new logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.favorite_rounded,
                          color: AppTheme.primaryOrange,
                          size: 26,
                        ),
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 10),
                    Text(
                      'Winkidoo',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: logoTextSize,
                        letterSpacing: -0.5,
                        color: Theme.of(context).colorScheme.onSurface,
                        shadows: [
                          if (brightness == Brightness.dark)
                            BoxShadow(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                              blurRadius: 16,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              if (title != null && !showLogo)
                Text(
                  title!,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              const Spacer(),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 8),
              ],
              if (levelCount > 0) ...[
                _LevelBadge(level: levelCount),
                const SizedBox(width: 8),
              ],
              _ActionBubble(
                icon: Icons.notifications_rounded,
                onTap: onNotificationTap,
                badgeCount: notificationCount,
              ),
              const SizedBox(width: 10),
              _StreakBubble(
                streakCount: streakCount,
                streakTier: streakTier,
                onTap: onStreakTap ?? onProfileTap,
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBubble extends StatefulWidget {
  const _ActionBubble({
    required this.icon,
    required this.onTap,
    required this.badgeCount,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int badgeCount;

  @override
  State<_ActionBubble> createState() => _ActionBubbleState();
}

class _ActionBubbleState extends State<_ActionBubble>
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
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          final scale = 1.0 - (_pressController.value * 0.08);
          return Transform.scale(scale: scale, child: child);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brightness == Brightness.dark
                    ? AppTheme.glassFillHover
                    : const Color(0x14000000),
                border: Border.all(
                  color: brightness == Brightness.dark
                      ? AppTheme.glassBorder
                      : AppTheme.lightGlassBorder,
                ),
              ),
              child: Icon(widget.icon,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                  size: 20),
            ),
            if (widget.badgeCount > 0)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryPink,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPink.withValues(alpha: 0.40),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: widget.badgeCount > 99 ? 7 : 9,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Streak-tier-aware fire bubble with color escalation.
class _StreakBubble extends StatefulWidget {
  const _StreakBubble({
    required this.streakCount,
    required this.streakTier,
    required this.onTap,
  });

  final int streakCount;
  final StreakTier streakTier;
  final VoidCallback? onTap;

  @override
  State<_StreakBubble> createState() => _StreakBubbleState();
}

class _StreakBubbleState extends State<_StreakBubble>
    with TickerProviderStateMixin {
  late final AnimationController _pressController;
  late final AnimationController _pulseController;

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.streakCount > 0) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _StreakBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streakCount > 0 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.streakCount == 0 && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  (List<Color>, Color) _tierColors() {
    switch (widget.streakTier) {
      case StreakTier.none:
        return (
          [const Color(0xFFFFF2A2), const Color(0xFFFFD645)],
          const Color(0xFF8C5D00)
        );
      case StreakTier.flame:
        return (
          [const Color(0xFFFF9A3E), const Color(0xFFFF6B2C)],
          Colors.white
        );
      case StreakTier.doubleFlame:
        return (
          [const Color(0xFFFF6B2C), const Color(0xFFFF4A1A)],
          Colors.white
        );
      case StreakTier.blueFlame:
        return (
          [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
          Colors.white
        );
      case StreakTier.legendary:
        return (
          [const Color(0xFFFFAA33), const Color(0xFFFF6B2C)],
          Colors.white
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (gradientColors, iconColor) = _tierColors();
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressController, _pulseController]),
        builder: (context, child) {
          final pressScale = 1.0 - (_pressController.value * 0.08);
          final pulseScale = 1.0 + (_pulseController.value * 0.04);
          return Transform.scale(
            scale: pressScale * pulseScale,
            child: child,
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.last.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                color: iconColor,
                size: 20,
              ),
            ),
            if (widget.streakCount > 0)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppTheme.primaryPink,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPink.withValues(alpha: 0.40),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.streakCount > 99
                        ? '99+'
                        : '${widget.streakCount}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: widget.streakCount > 99 ? 7 : 9,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF9A42), Color(0xFFFF6B1A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B1A).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'Lv $level',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
