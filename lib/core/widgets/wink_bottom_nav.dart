import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

class WinkBottomNav extends StatelessWidget {
  const WinkBottomNav({
    super.key,
    required this.currentIndex,
    required this.onIndexTap,
    required this.onCenterTap,
  });

  final int currentIndex;
  final ValueChanged<int> onIndexTap;
  final VoidCallback onCenterTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        decoration: BoxDecoration(
          color: AppTheme.navBg(brightness),
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppTheme.toyCardShadow(brightness),
        ),
        child: Row(
          children: [
            Expanded(
                child: _NavItem(
                    index: 0,
                    currentIndex: currentIndex,
                    icon: Icons.home_rounded,
                    label: 'Home',
                    onTap: onIndexTap)),
            Expanded(
                child: _NavItem(
                    index: 1,
                    currentIndex: currentIndex,
                    icon: Icons.inbox_rounded,
                    label: 'Vault',
                    onTap: onIndexTap)),
            _CenterAction(onTap: onCenterTap),
            Expanded(
                child: _NavItem(
                    index: 2,
                    currentIndex: currentIndex,
                    icon: Icons.emoji_emotions_rounded,
                    label: 'Winks',
                    onTap: onIndexTap)),
            Expanded(
                child: _NavItem(
                    index: 3,
                    currentIndex: currentIndex,
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    onTap: onIndexTap)),
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
  });

  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    final brightness = Theme.of(context).brightness;
    final color = isActive
        ? AppTheme.navActive(brightness)
        : AppTheme.navInactive(brightness);

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
  const _CenterAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            width: 88,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFEA6B), Color(0xFFFFCC31)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55FFCD34),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: Color(0xFF8C5D00), size: 28),
          ),
        ),
      ),
    );
  }
}
