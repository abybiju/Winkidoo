import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

class PlayHeader extends StatelessWidget {
  const PlayHeader({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final titleSize = compact ? 28.0 : 34.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE PLAY FLOOR',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: brightness == Brightness.dark
                ? AppTheme.textSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'pick a ',
                style: GoogleFonts.poppins(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: brightness == Brightness.dark
                      ? AppTheme.textPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.ctaGoldA, AppTheme.primaryOrange],
          ).createShader(bounds),
          child: Text(
            'card.',
            style: GoogleFonts.poppins(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
