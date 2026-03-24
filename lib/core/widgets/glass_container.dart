import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

/// A reusable frosted glass container with real [BackdropFilter] blur.
///
/// Wraps any [child] in a glassmorphism panel with configurable blur,
/// tint, border, and border-radius. Use for cards, overlays, and sheets.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.blurSigma,
    this.fillColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double? blurSigma;
  final Color? fillColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final sigma = blurSigma ?? AppTheme.glassBlurSigma;
    final fill = fillColor ??
        (brightness == Brightness.dark
            ? AppTheme.glassFill
            : AppTheme.lightGlassFill);
    final border = borderColor ??
        (brightness == Brightness.dark
            ? AppTheme.glassBorder
            : AppTheme.lightGlassBorder);
    final shadows = boxShadow ?? AppTheme.elevation1(brightness);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border, width: borderWidth),
            boxShadow: shadows,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
