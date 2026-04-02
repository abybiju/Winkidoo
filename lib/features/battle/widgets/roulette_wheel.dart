import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

/// Spinning roulette wheel that resolves to a difficulty segment.
/// Calls [onResult] with the resolved segment string after the spin stops.
class RouletteWheel extends StatefulWidget {
  const RouletteWheel({super.key, required this.onResult});

  final void Function(String result) onResult;

  @override
  State<RouletteWheel> createState() => _RouletteWheelState();
}

class _RouletteWheelState extends State<RouletteWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  String? _result;
  bool _spinning = false;

  static const _segments = [
    _Segment('easy', 'Easy', Color(0xFF4CAF50), 0.30),
    _Segment('medium', 'Medium', Color(0xFFFFA726), 0.30),
    _Segment('hard', 'Hard', Color(0xFFEF5350), 0.25),
    _Segment('chaos', 'CHAOS', Color(0xFF7C4DFF), 0.10),
    _Segment('golden', 'GOLDEN', Color(0xFFFFD700), 0.05),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _rotation = Tween<double>(begin: 0, end: 0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _pickResult() {
    final rand = Random().nextDouble();
    double cumulative = 0;
    for (final seg in _segments) {
      cumulative += seg.weight;
      if (rand <= cumulative) return seg.id;
    }
    return _segments.first.id;
  }

  double _angleForResult(String resultId) {
    double startAngle = 0;
    for (final seg in _segments) {
      final sweep = seg.weight * 2 * pi;
      if (seg.id == resultId) {
        // Land in the middle of this segment
        return startAngle + sweep / 2;
      }
      startAngle += sweep;
    }
    return 0;
  }

  void _spin() {
    if (_spinning) return;
    setState(() => _spinning = true);
    HapticFeedback.mediumImpact();

    final result = _pickResult();
    final targetAngle = _angleForResult(result);
    // Spin 4-6 full rotations + land on target
    final fullSpins = (4 + Random().nextInt(3)) * 2 * pi;
    final endAngle = fullSpins + (2 * pi - targetAngle);

    _rotation = Tween<double>(begin: 0, end: endAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward(from: 0).then((_) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _result = result);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) widget.onResult(result);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _result != null
              ? _labelFor(_result!)
              : 'Spin the wheel!',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _result != null
                ? _colorFor(_result!)
                : AppTheme.homeTextPrimary,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Wheel
              AnimatedBuilder(
                animation: _rotation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotation.value,
                    child: child,
                  );
                },
                child: CustomPaint(
                  size: const Size(260, 260),
                  painter: _WheelPainter(_segments),
                ),
              ),
              // Pointer arrow at top
              Positioned(
                top: 0,
                child: Icon(
                  Icons.arrow_drop_down,
                  size: 40,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              // Center circle
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.glassFill,
                  border: Border.all(color: Colors.white54, width: 2),
                ),
                child: const Icon(Icons.casino, color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        if (!_spinning && _result == null)
          GestureDetector(
            onTap: _spin,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                color: AppTheme.primaryOrange,
              ),
              child: Text(
                'SPIN',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        if (_result != null)
          Text(
            _subtitleFor(_result!),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.homeTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  String _labelFor(String id) {
    switch (id) {
      case 'chaos':
        return 'CHAOS MODE';
      case 'golden':
        return 'GOLDEN HOUR';
      default:
        return '${id[0].toUpperCase()}${id.substring(1)} Difficulty';
    }
  }

  String _subtitleFor(String id) {
    switch (id) {
      case 'chaos':
        return 'The judge has gone unhinged...';
      case 'golden':
        return 'Easy battle + 3x XP!';
      case 'hard':
        return 'Good luck. You\'ll need it.';
      case 'medium':
        return 'A fair challenge awaits.';
      default:
        return 'The judge is feeling generous.';
    }
  }

  Color _colorFor(String id) {
    for (final seg in _segments) {
      if (seg.id == id) return seg.color;
    }
    return Colors.white;
  }
}

class _Segment {
  const _Segment(this.id, this.label, this.color, this.weight);
  final String id;
  final String label;
  final Color color;
  final double weight;
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.segments);
  final List<_Segment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    double startAngle = -pi / 2; // Start at top

    for (final seg in segments) {
      final sweepAngle = seg.weight * 2 * pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Border
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Label
      final labelAngle = startAngle + sweepAngle / 2;
      final labelRadius = radius * 0.65;
      final labelOffset = Offset(
        center.dx + labelRadius * cos(labelAngle),
        center.dy + labelRadius * sin(labelAngle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: seg.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(labelOffset.dx, labelOffset.dy);
      canvas.rotate(labelAngle + pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
