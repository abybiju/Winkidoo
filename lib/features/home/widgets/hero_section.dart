import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/home/widgets/avatar_selector.dart';

class SmallHeroGlowStrip extends StatefulWidget {
  const SmallHeroGlowStrip({
    super.key,
    this.height = 140,
    required this.items,
    this.onAvatarTap,
  });

  final double height;
  final List<HomeAvatarOption> items;
  final ValueChanged<HomeAvatarOption>? onAvatarTap;

  @override
  State<SmallHeroGlowStrip> createState() => _SmallHeroGlowStripState();
}

class HeroSection extends SmallHeroGlowStrip {
  const HeroSection({
    super.key,
    super.height,
    required super.items,
    super.onAvatarTap,
  });
}

class _SmallHeroGlowStripState extends State<SmallHeroGlowStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
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
    final brightness = Theme.of(context).brightness;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppTheme.homeBackgroundGradient(brightness),
        ),
        border: Border.all(color: AppTheme.premiumBorder30(brightness)),
        boxShadow: AppTheme.premiumElevation(brightness),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _GlowStripPainter(
                    progress: _controller.value,
                    lineColor: AppTheme.orbitalLine.withValues(alpha: 0.26),
                    sparkColor: AppTheme.sparkColor.withValues(alpha: 0.24),
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
              child: Column(
                children: [
                  Expanded(
                    child: AvatarSelector(
                      items: widget.items,
                      onTap: widget.onAvatarTap,
                      showLabels: false,
                      showHint: false,
                      homeCompactMode: true,
                    ),
                  ),
                  Text(
                    'Tap an avatar to challenge!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowStripPainter extends CustomPainter {
  const _GlowStripPainter({
    required this.progress,
    required this.lineColor,
    required this.sparkColor,
  });

  final double progress;
  final Color lineColor;
  final Color sparkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final center = Offset(size.width / 2, size.height * 0.68);
    canvas.drawArc(
      Rect.fromCenter(
          center: center, width: size.width * 1.25, height: size.height * 1.55),
      math.pi,
      math.pi,
      false,
      ringPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
          center: center, width: size.width * 0.95, height: size.height * 1.2),
      math.pi,
      math.pi,
      false,
      ringPaint,
    );

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.3),
        radius: 1.0,
        colors: [
          AppTheme.homeGlowPink.withValues(alpha: 0.14),
          AppTheme.homeGlowOrange.withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glowPaint);

    final sparkPaint = Paint()..color = sparkColor;
    final phase = progress * 2 * math.pi;
    final points = <Offset>[
      Offset(size.width * 0.16, size.height * 0.38),
      Offset(size.width * 0.34, size.height * 0.24),
      Offset(size.width * 0.57, size.height * 0.31),
      Offset(size.width * 0.74, size.height * 0.22),
      Offset(size.width * 0.88, size.height * 0.42),
    ];

    for (var i = 0; i < points.length; i++) {
      final pulse = 0.8 + (0.7 * math.sin(phase + i));
      canvas.drawCircle(points[i], pulse.clamp(0.5, 1.6), sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowStripPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.sparkColor != sparkColor;
  }
}
