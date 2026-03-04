import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

class WinkNavIconSet {
  const WinkNavIconSet({
    required this.home,
    required this.vault,
    required this.winks,
    required this.profile,
    required this.battle,
  });

  final IconData home;
  final IconData vault;
  final IconData winks;
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
          : const Color(0xFFE8ECF8),
      border: brightness == Brightness.dark
          ? AppTheme.footerStroke
          : const Color(0x668B7BAA),
      active: brightness == Brightness.dark
          ? AppTheme.footerActive
          : const Color(0xFF8C5D00),
      inactive: brightness == Brightness.dark
          ? AppTheme.footerInactive
          : const Color(0xFF887B9A),
      centerBackground: brightness == Brightness.dark
          ? AppTheme.footerCenter
          : const Color(0xFFD8A92F),
      centerForeground: brightness == Brightness.dark
          ? AppTheme.footerCenterOn
          : const Color(0xFF332600),
      icons: const WinkNavIconSet(
        home: PhosphorIconsFill.houseSimple,
        vault: PhosphorIconsFill.archive,
        winks: PhosphorIconsFill.smileyWink,
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
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        decoration: BoxDecoration(
          color: resolvedStyle.background.withValues(
            alpha: brightness == Brightness.dark ? 0.92 : 0.95,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: resolvedStyle.border),
          boxShadow: AppTheme.toyCardShadow(brightness),
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
                    icon: resolvedStyle.icons.winks,
                    label: 'Winks',
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
    );
  }
}

class _NavItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    final color = isActive ? style.active : style.inactive;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  const _CenterAction({required this.onTap, required this.style});

  final VoidCallback onTap;
  final WinkBottomNavStyle style;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Transform.translate(
        offset: const Offset(0, -6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: Ink(
              width: 114,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: style.centerBackground,
                border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
                boxShadow: [
                  ...AppTheme.premiumElevation(brightness),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(style.icons.battle,
                      color: style.centerForeground, size: 20),
                  const SizedBox(width: 2),
                  Text(
                    'Battle',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: style.centerForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
