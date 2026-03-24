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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white
            .withValues(alpha: brightness == Brightness.dark ? 0.03 : 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.premiumBorder30(brightness)),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: brightness == Brightness.dark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showLogo)
            Row(
              children: [
                SizedBox(width: compact ? 6 : 8),
                SizedBox(
                  height: computedLogoSize,
                  width: computedLogoSize,
                  child: Image.asset(
                    'assets/images/winkidoo new logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFF5C76B),
                      size: 26,
                    ),
                  ),
                ),
                SizedBox(width: compact ? 8 : 10),
                Text(
                  'Winkidoo',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: logoTextSize,
                    color: Theme.of(context).colorScheme.onSurface,
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
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          const Spacer(),
          if (trailing != null) ...[
            trailing!,
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
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ActionBubble extends StatelessWidget {
  const _ActionBubble({
    required this.icon,
    required this.onTap,
    required this.badgeCount,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF2A2), Color(0xFFFFD645)],
              ),
            ),
            child: Icon(icon, color: const Color(0xFF8C5D00), size: 22),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE85D93),
              ),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: badgeCount > 99 ? 8 : 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Streak-tier-aware fire bubble with color escalation.
class _StreakBubble extends StatelessWidget {
  const _StreakBubble({
    required this.streakCount,
    required this.streakTier,
    required this.onTap,
  });

  final int streakCount;
  final StreakTier streakTier;
  final VoidCallback? onTap;

  (List<Color>, Color) _tierColors() {
    switch (streakTier) {
      case StreakTier.none:
        return ([const Color(0xFFFFF2A2), const Color(0xFFFFD645)], const Color(0xFF8C5D00));
      case StreakTier.flame:
        return ([const Color(0xFFFF9A3E), const Color(0xFFFF6B2C)], Colors.white);
      case StreakTier.doubleFlame:
        return ([const Color(0xFFFF6B2C), const Color(0xFFE85D93)], Colors.white);
      case StreakTier.blueFlame:
        return ([const Color(0xFF3B82F6), const Color(0xFF8B5CF6)], Colors.white);
      case StreakTier.legendary:
        return ([const Color(0xFFF5C76B), const Color(0xFFFF6B2C)], Colors.white);
    }
  }


  @override
  Widget build(BuildContext context) {
    final (gradientColors, iconColor) = _tierColors();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: iconColor,
              size: 22,
            ),
          ),
        ),
        if (streakCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFE85D93),
              ),
              child: Text(
                streakCount > 99 ? '99+' : '$streakCount',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: streakCount > 99 ? 8 : 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
