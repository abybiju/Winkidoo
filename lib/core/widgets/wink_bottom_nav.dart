import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

class WinkNavIconSet {
  const WinkNavIconSet({
    required this.home,
    required this.vault,
    required this.play,
    required this.profile,
    required this.battle,
  });

  final IconData home;
  final IconData vault;
  final IconData play;
  final IconData profile;
  final IconData battle;
}

class WinkBottomNavStyle {
  const WinkBottomNavStyle({
    required this.background,
    required this.border,
    required this.active,
    required this.inactive,
    required this.centerBackground,
    required this.centerForeground,
    required this.icons,
  });

  final Color background;
  final Color border;
  final Color active;
  final Color inactive;
  final Color centerBackground;
  final Color centerForeground;
  final WinkNavIconSet icons;

  factory WinkBottomNavStyle.defaultStyle(Brightness brightness) {
    return WinkBottomNavStyle(
      background: brightness == Brightness.dark
          ? AppTheme.footerBase
          : const Color(0xFFF0ECF8),
      border: brightness == Brightness.dark
          ? AppTheme.glassBorder
          : const Color(0x33A06DAF),
      active: brightness == Brightness.dark
          ? AppTheme.footerActive
          : const Color(0xFFD06A1A),
      inactive: brightness == Brightness.dark
          ? AppTheme.footerInactive
          : const Color(0xFF887B9A),
      centerBackground: brightness == Brightness.dark
          ? AppTheme.footerCenter
          : const Color(0xFFE07020),
      centerForeground: brightness == Brightness.dark
          ? AppTheme.footerCenterOn
          : Colors.white,
      icons: const WinkNavIconSet(
        home: PhosphorIconsFill.houseSimple,
        vault: PhosphorIconsFill.archive,
        play: PhosphorIconsFill.gameController,
        profile: PhosphorIconsFill.userCircle,
        battle: PhosphorIconsBold.sword,
      ),
    );
  }
}

class WinkBottomNav extends StatelessWidget {
  const WinkBottomNav({
    super.key,
    required this.currentIndex,
    required this.onIndexTap,
    required this.onCenterTap,
    this.style,
  });

  final int currentIndex;
  final ValueChanged<int> onIndexTap;
  final VoidCallback onCenterTap;
  final WinkBottomNavStyle? style;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final resolvedStyle = style ?? WinkBottomNavStyle.defaultStyle(brightness);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppTheme.glassBlurSigma,
              sigmaY: AppTheme.glassBlurSigma,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
              decoration: BoxDecoration(
                color: resolvedStyle.background.withValues(
                  alpha: brightness == Brightness.dark ? 0.80 : 0.85,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: resolvedStyle.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: brightness == Brightness.dark ? 0.40 : 0.12,
                    ),
                    blurRadius: 30,
                    offset: const Offset(0, -4),
                  ),
                  if (brightness == Brightness.dark)
                    BoxShadow(
                      color: AppTheme.plum.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -2),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                      child: _NavItem(
                          index: 0,
                          currentIndex: currentIndex,
                          icon: resolvedStyle.icons.home,
                          label: 'Home',
                          onTap: onIndexTap,
                          style: resolvedStyle)),
                  Expanded(
                      child: _NavItem(
                          index: 1,
                          currentIndex: currentIndex,
                          icon: resolvedStyle.icons.vault,
                          label: 'Vault',
                          onTap: onIndexTap,
                          style: resolvedStyle)),
                  _CenterAction(onTap: onCenterTap, style: resolvedStyle),
                  Expanded(
                      child: _NavItem(
                          index: 2,
                          currentIndex: currentIndex,
                          icon: resolvedStyle.icons.play,
                          label: 'Play',
                          onTap: onIndexTap,
                          style: resolvedStyle)),
                  Expanded(
                      child: _NavItem(
                          index: 3,
                          currentIndex: currentIndex,
                          icon: resolvedStyle.icons.profile,
                          label: 'Profile',
                          onTap: onIndexTap,
                          style: resolvedStyle)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.style,
  });

  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;
  final WinkBottomNavStyle style;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppTheme.microDuration,
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 0.0,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.index == widget.currentIndex;
    final color = isActive ? widget.style.active : widget.style.inactive;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        HapticFeedback.selectionClick();
        widget.onTap(widget.index);
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          final scale = 1.0 - (_scaleController.value * 0.08);
          return Transform.scale(scale: scale, child: child);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppTheme.microDuration,
                curve: AppTheme.standardCurve,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isActive
                      ? color.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(widget.icon, color: color, size: isActive ? 22 : 20),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: AppTheme.microDuration,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(widget.label),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: AppTheme.microDuration,
                width: isActive ? 4 : 0,
                height: isActive ? 4 : 0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? widget.style.active : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterAction extends StatefulWidget {
  const _CenterAction({required this.onTap, required this.style});

  final VoidCallback onTap;
  final WinkBottomNavStyle style;

  @override
  State<_CenterAction> createState() => _CenterActionState();
}

class _CenterActionState extends State<_CenterAction>
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
        vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _pressController.reverse(),
        child: AnimatedBuilder(
          animation: Listenable.merge([_pressController, _pulseController]),
          builder: (context, child) {
            final scale = 1.0 - (_pressController.value * 0.06);
            final pulse = 1.0 + (_pulseController.value * 0.03);
            return Transform.scale(
              scale: scale * pulse,
              child: Transform.translate(
                offset: const Offset(0, -8),
                child: child,
              ),
            );
          },
          child: Container(
            width: 108,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.style.centerBackground,
                  widget.style.centerBackground.withValues(alpha: 0.85),
                ],
              ),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.28), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: widget.style.centerBackground.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
                ...AppTheme.elevation2(brightness),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.style.icons.battle,
                    color: widget.style.centerForeground, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Battle',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: widget.style.centerForeground,
                    letterSpacing: -0.2,
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
