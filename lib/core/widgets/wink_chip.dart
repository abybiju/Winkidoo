import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

class WinkChip extends StatelessWidget {
  const WinkChip({
    super.key,
    required this.label,
    this.icon,
    this.isActive = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.microDuration,
        curve: AppTheme.standardCurve,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          color: isActive
              ? AppTheme.primaryOrange
              : (brightness == Brightness.dark
                  ? AppTheme.glassFill
                  : AppTheme.lightGlassFill),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryOrange.withValues(alpha: 0.60)
                : (brightness == Brightness.dark
                    ? AppTheme.glassBorder
                    : AppTheme.lightGlassBorder),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.20),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? Colors.white
                    : (brightness == Brightness.dark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : (brightness == Brightness.dark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
