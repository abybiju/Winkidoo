import 'dart:math';
import 'package:flutter/material.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

/// Reusable cosmic gradient background with optional star particles and glow overlay.
class CosmicBackground extends StatelessWidget {
  const CosmicBackground({
    super.key,
    required this.child,
    this.showStars = false,
    this.glowColor,
    this.glowAlignment = const Alignment(0.6, -0.4),
    this.glowRadius = 0.7,
  });

  final Widget child;
  final bool showStars;
  final Color? glowColor;
  final Alignment glowAlignment;
  final double glowRadius;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = AppTheme.cosmicBackgroundGradient(brightness);

    return Stack(
      children: [
        // Base gradient
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
                stops: colors.length == 3 ? const [0.0, 0.5, 1.0] : null,
              ),
            ),
          ),
        ),
        // Optional radial glow
        if (glowColor != null)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: glowAlignment,
                  radius: glowRadius,
                  colors: [
                    glowColor!.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        // Optional star particles
        if (showStars && brightness == Brightness.dark)
          const Positioned.fill(
            child: _StarField(),
          ),
        // Content
        child,
      ],
    );
  }
}

class _StarField extends StatefulWidget {
  const _StarField();

  @override
  State<_StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<_StarField> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final rng = Random(42);
    _stars = List.generate(50, (_) => _Star(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: 0.5 + rng.nextDouble() * 1.5,
      opacity: 0.1 + rng.nextDouble() * 0.5,
      speed: 0.2 + rng.nextDouble() * 0.6,
    ));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _StarPainter(stars: _stars, progress: _controller.value),
        );
      },
    );
  }
}

class _Star {
  final double x, y, size, opacity, speed;
  const _Star({required this.x, required this.y, required this.size, required this.opacity, required this.speed});
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double progress;

  _StarPainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      // Slow drift animation
      final dx = star.x * size.width + (progress * star.speed * 20) % size.width;
      final dy = star.y * size.height;
      // Twinkle effect
      final twinkle = (0.5 + 0.5 * (progress * star.speed * 6.28).remainder(6.28)).abs();
      final alpha = star.opacity * (0.4 + 0.6 * twinkle);

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dx % size.width, dy), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.progress != progress;
}
