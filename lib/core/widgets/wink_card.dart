import 'package:flutter/material.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

/// Premium card container with multiple display styles.
///
/// Styles:
///  • Default — gradient fill with elevation
///  • Glass — frosted glass (use [GlassContainer] if real blur needed)
///  • Flat — minimal, no border, subtle background
class WinkCard extends StatefulWidget {
  const WinkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.onTap,
    this.gradient,
    this.borderColor,
    this.boxShadow,
    this.enablePressAnimation = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final bool enablePressAnimation;

  @override
  State<WinkCard> createState() => _WinkCardState();
}

class _WinkCardState extends State<WinkCard>
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
    final decoration = BoxDecoration(
      gradient: widget.gradient ??
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.cardGradientA(brightness),
              AppTheme.cardGradientB(brightness),
            ],
          ),
      borderRadius: BorderRadius.circular(widget.borderRadius),
      border: Border.all(
        color: widget.borderColor ??
            AppTheme.premiumBorder30(brightness),
      ),
      boxShadow: widget.boxShadow ?? AppTheme.elevation2(brightness),
    );

    Widget content = Padding(padding: widget.padding, child: widget.child);

    if (widget.onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    if (!widget.enablePressAnimation) {
      return DecoratedBox(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: content,
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          final scale = 1.0 - (_pressController.value * 0.025);
          return Transform.scale(scale: scale, child: child);
        },
        child: DecoratedBox(decoration: decoration, child: content),
      ),
    );
  }
}
