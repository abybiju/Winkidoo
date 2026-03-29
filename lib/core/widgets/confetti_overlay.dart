import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

/// Reusable confetti overlay. Call [controller.play()] to trigger.
/// Place as a Stack child on top of your content.
class ConfettiOverlay extends StatelessWidget {
  const ConfettiOverlay({
    super.key,
    required this.controller,
    this.alignment = Alignment.topCenter,
    this.numberOfParticles = 30,
    this.gravity = 0.2,
  });

  final ConfettiController controller;
  final Alignment alignment;
  final int numberOfParticles;
  final double gravity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConfettiWidget(
        confettiController: controller,
        blastDirectionality: BlastDirectionality.explosive,
        numberOfParticles: numberOfParticles,
        colors: const [
          AppTheme.primaryOrange,
          AppTheme.premiumAmber,
          AppTheme.secondaryViolet,
          AppTheme.primaryOrangeLight,
        ],
        gravity: gravity,
        shouldLoop: false,
      ),
    );
  }
}
