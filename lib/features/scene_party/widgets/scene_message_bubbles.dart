import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/character_chat_message.dart';

/// Full-width Director message — the AI host's narration, twists, and
/// Best Performance awards. Rendered for message_type 'director'.
class DirectorBubble extends StatelessWidget {
  const DirectorBubble({super.key, required this.message});

  final CharacterChatMessage message;

  bool get _isBestPerformance =>
      (message.payload?['type'] as String?) == 'best_performance';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isBestPerformance
              ? AppTheme.primaryOrange.withValues(alpha: 0.6)
              : AppTheme.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isBestPerformance
                    ? PhosphorIconsFill.trophy
                    : PhosphorIconsFill.filmSlate,
                size: 14,
                color: AppTheme.primaryOrange,
              ),
              const SizedBox(width: 6),
              Text(
                _isBestPerformance ? 'BEST PERFORMANCE' : 'DIRECTOR',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.displayContent,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

/// Left-aligned castmate bubble — an AI-played character's line.
/// Rendered for message_type 'castmate'.
class CastmateBubble extends StatelessWidget {
  const CastmateBubble({super.key, required this.message});

  final CharacterChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: AppTheme.glassFill,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.characterName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '· AI castmate',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              message.displayContent,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered, subdued system line (scene events).
class SceneSystemLine extends StatelessWidget {
  const SceneSystemLine({super.key, required this.message});

  final CharacterChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          message.displayContent,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
