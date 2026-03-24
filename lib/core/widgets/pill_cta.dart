import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

enum PillCtaStyle { standard, layered, glass }

class PillCta extends StatefulWidget {
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
  State<PillCta> createState() => _PillCtaState();
}

class _PillCtaState extends State<PillCta>
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
    final defaultBg = widget.filled
        ? AppTheme.pillBg(brightness)
        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.78);
    final defaultFg = widget.filled
        ? AppTheme.navTextStrong(brightness)
        : Theme.of(context).colorScheme.onSurface;

    Gradient? bgGradient;
    Color bgColor = defaultBg;
    Color fg = defaultFg;
    Color borderColor = AppTheme.pillBorder(brightness);
    double borderWidth = 1;
    List<BoxShadow> boxShadow = AppTheme.elevation1(brightness);

    switch (widget.style) {
      case PillCtaStyle.standard:
        break;
      case PillCtaStyle.layered:
        bgGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.vaultCtaPrimaryA, AppTheme.vaultCtaPrimaryB],
        );
        fg = Colors.white;
        borderColor = Colors.white.withValues(alpha: 0.22);
        borderWidth = 1.2;
        boxShadow = [
          BoxShadow(
            color: AppTheme.vaultCtaPrimaryB.withValues(alpha: 0.30),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          ...AppTheme.elevation1(brightness),
        ];
        break;
      case PillCtaStyle.glass:
        bgColor = brightness == Brightness.dark
            ? AppTheme.glassFill
            : Colors.white.withValues(alpha: 0.72);
        fg = Theme.of(context).colorScheme.onSurface;
        borderColor = brightness == Brightness.dark
            ? AppTheme.glassBorder
            : const Color(0x33A06DAF);
        borderWidth = 1;
        boxShadow = AppTheme.elevation1(brightness);
        break;
    }

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          final scale = 1.0 - (_pressController.value * 0.04);
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            color: bgGradient == null ? bgColor : null,
            gradient: bgGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: boxShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: Stack(
              children: [
                if (widget.style == PillCtaStyle.layered)
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
                          stops: [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact ? 16 : 20,
                    vertical: widget.compact ? 10 : 13,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null && !widget.trailing) ...[
                        Icon(widget.icon,
                            size: widget.compact ? 16 : 18, color: fg),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: GoogleFonts.poppins(
                          fontSize: widget.compact ? 14 : 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: fg,
                        ),
                      ),
                      if (widget.icon != null && widget.trailing) ...[
                        const SizedBox(width: 8),
                        Icon(widget.icon,
                            size: widget.compact ? 16 : 18, color: fg),
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
