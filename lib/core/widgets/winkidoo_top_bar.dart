import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

class WinkidooTopBar extends StatelessWidget {
  const WinkidooTopBar({
    super.key,
    this.title,
    this.showLogo = true,
    this.notificationCount = 0,
    this.streakCount = 0,
    this.onNotificationTap,
    this.onStreakTap,
    this.onProfileTap,
    this.trailing,
  });

  final String? title;
  final bool showLogo;
  final int notificationCount;
  final int streakCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onStreakTap;
  final VoidCallback? onProfileTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  width: 32,
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
                const SizedBox(width: 10),
                Text(
                  'Winkidoo',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
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
          _ActionBubble(
            icon: Icons.local_fire_department_rounded,
            onTap: onStreakTap ?? onProfileTap,
            badgeCount: streakCount,
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
