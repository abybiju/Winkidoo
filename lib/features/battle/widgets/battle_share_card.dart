import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/home/home_screen.dart';

/// A non-interactive widget rendered to an image for sharing.
/// Shows judge avatar, best quote, outcome, and branding.
class BattleShareCard extends StatelessWidget {
  const BattleShareCard({
    super.key,
    required this.judgePersona,
    required this.bestQuote,
    required this.won,
    required this.difficulty,
    this.seekerScore,
  });

  final String judgePersona;
  final String bestQuote;
  final bool won;
  final int difficulty;
  final int? seekerScore;

  @override
  Widget build(BuildContext context) {
    final personaName = HomeScreen.personaDisplayName(judgePersona);
    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1030), Color(0xFF2A1048)],
        ),
        border: Border.all(
          color: won
              ? AppTheme.premiumGold.withValues(alpha: 0.5)
              : AppTheme.primaryPink.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (won ? AppTheme.premiumGold : AppTheme.primaryPink)
                .withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Result badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: won
                  ? AppTheme.premiumGold.withValues(alpha: 0.2)
                  : AppTheme.primaryPink.withValues(alpha: 0.15),
              border: Border.all(
                color: won
                    ? AppTheme.premiumGold.withValues(alpha: 0.5)
                    : AppTheme.primaryPink.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              won ? '\u{1F513} UNLOCKED' : '\u{1F512} DENIED',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: won ? AppTheme.premiumGold : AppTheme.primaryPink,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Judge persona
          Text(
            personaName,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          // Difficulty stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return Icon(
                Icons.star_rounded,
                size: 16,
                color: i < difficulty
                    ? AppTheme.premiumGold
                    : Colors.white.withValues(alpha: 0.15),
              );
            }),
          ),
          const SizedBox(height: 20),
          // Quote
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '\u{201C}',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryPink.withValues(alpha: 0.5),
                    height: 0.8,
                  ),
                ),
                Text(
                  bestQuote,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (seekerScore != null) ...[
            const SizedBox(height: 12),
            Text(
              'Persuasion Score: $seekerScore',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Winkidoo',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.premiumGold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '\u{2022} Unlock the surprise',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
