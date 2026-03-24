import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

class CosmicEmptyState extends StatelessWidget {
  const CosmicEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCtaTap,
    this.iconSize = 72,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize + 24,
              height: iconSize + 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryOrange.withValues(alpha: 0.06),
                border: Border.all(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.10),
                ),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: AppTheme.primaryOrange.withValues(alpha: 0.50),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: brightness == Brightness.dark
                    ? AppTheme.textPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: brightness == Brightness.dark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
            if (ctaLabel != null && onCtaTap != null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onCtaTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppTheme.orangeCtaGradient(brightness),
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    ctaLabel!,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
