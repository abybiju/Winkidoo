import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/services/phantom_judge_service.dart';

/// Full-screen glitch overlay when a phantom judge takes over.
/// Shows the phantom name + emoji with a glitch animation, then fades out.
class PhantomOverlay extends StatefulWidget {
  const PhantomOverlay({super.key, required this.phantom, this.onDismiss});

  final PhantomPersona phantom;
  final VoidCallback? onDismiss;

  @override
  State<PhantomOverlay> createState() => _PhantomOverlayState();
}

class _PhantomOverlayState extends State<PhantomOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _glitch;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 30),
    ]).animate(_controller);

    _glitch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.7), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 50),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onDismiss?.call();
    });
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
      builder: (context, child) {
        final glitchOffset = _glitch.value * (Random().nextDouble() * 20 - 10);
        return Opacity(
          opacity: _opacity.value,
          child: Container(
            color: Colors.black.withValues(alpha: 0.85),
            child: Center(
              child: Transform.translate(
                offset: Offset(glitchOffset, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.phantom.emoji,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'PHANTOM TAKEOVER',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade300,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.phantom.name,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'has seized control',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
