import 'package:flutter/material.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

/// A shimmer sweep effect that overlays any child widget.
///
/// Animates a diagonal gradient sweep across the child, creating
/// a polished "loading glow" effect. Used by skeleton loaders and
/// premium card borders.
class ShimmerEffect extends StatefulWidget {
  const ShimmerEffect({
    super.key,
    required this.child,
    this.duration,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
  });

  final Widget child;
  final Duration? duration;
  final Color? baseColor;
  final Color? highlightColor;
  final bool enabled;

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? AppTheme.shimmerDuration,
    );
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final brightness = Theme.of(context).brightness;
    final base = widget.baseColor ?? Colors.transparent;
    final highlight = widget.highlightColor ??
        (brightness == Brightness.dark
            ? const Color(0x0FFF8C42)
            : Colors.white.withValues(alpha: 0.50));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final x = -1.5 + (3.0 * _controller.value);
        return Stack(
          children: [
            child!,
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(x, -0.3),
                      end: Alignment(x + 0.8, 0.3),
                      colors: [base, highlight, base],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
