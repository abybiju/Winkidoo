import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

enum PillCtaStyle { standard, layered, glass }

class PillCta extends StatelessWidget {
  const PillCta({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.trailing = false,
    this.filled = true,
    this.compact = false,
    this.style = PillCtaStyle.standard,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool trailing;
  final bool filled;
  final bool compact;
  final PillCtaStyle style;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final defaultBg = filled
        ? AppTheme.pillBg(brightness)
        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.78);
    final defaultFg = filled
        ? AppTheme.navTextStrong(brightness)
        : Theme.of(context).colorScheme.onSurface;

    Gradient? bgGradient;
    Color bgColor = defaultBg;
    Color fg = defaultFg;
    Color borderColor = AppTheme.pillBorder(brightness);
    double borderWidth = 1;
    List<BoxShadow> boxShadow = AppTheme.toyPillShadow(brightness);

    switch (style) {
      case PillCtaStyle.standard:
        break;
      case PillCtaStyle.layered:
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.vaultCtaPrimaryA, AppTheme.vaultCtaPrimaryB],
        );
        fg = Colors.white;
        borderColor = Colors.white.withValues(alpha: 0.28);
        borderWidth = 1.2;
        boxShadow = [
          BoxShadow(
            color: AppTheme.vaultCtaPrimaryB.withValues(alpha: 0.36),
            blurRadius: 16,
            spreadRadius: 0.5,
            offset: const Offset(0, 5),
          ),
          ...AppTheme.toyPillShadow(brightness),
        ];
        break;
      case PillCtaStyle.glass:
        bgColor = brightness == Brightness.dark
            ? AppTheme.vaultCtaSecondaryFill
            : Colors.white.withValues(alpha: 0.62);
        fg = Theme.of(context).colorScheme.onSurface;
        borderColor = brightness == Brightness.dark
            ? AppTheme.vaultCtaSecondaryStroke
            : const Color(0x66A06DAF);
        borderWidth = 1.1;
        boxShadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            color: bgGradient == null ? bgColor : null,
            gradient: bgGradient,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: boxShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                if (style == PillCtaStyle.layered)
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.vaultCtaInnerGlow,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.6],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 14 : 18,
                    vertical: compact ? 10 : 12,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
