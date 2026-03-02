import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

class PillCta extends StatelessWidget {
  const PillCta({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.trailing = false,
    this.filled = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool trailing;
  final bool filled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bg = filled
        ? AppTheme.pillBg(brightness)
        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.78);
    final fg = filled
        ? AppTheme.navTextStrong(brightness)
        : Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 18,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.pillBorder(brightness)),
            boxShadow: AppTheme.toyPillShadow(brightness),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null && !trailing) ...[
                Icon(icon, size: compact ? 16 : 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              if (icon != null && trailing) ...[
                const SizedBox(width: 8),
                Icon(icon, size: compact ? 16 : 18, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
