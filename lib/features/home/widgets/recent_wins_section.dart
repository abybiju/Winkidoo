import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/surprise.dart';

class RecentWins extends StatelessWidget {
  const RecentWins({
    super.key,
    required this.surprises,
    required this.judgeNameForPersona,
    this.onSeeAll,
    this.itemHeight = 96,
  });

  final List<Surprise> surprises;
  final String Function(String personaId) judgeNameForPersona;
  final VoidCallback? onSeeAll;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final compact = itemHeight < 96;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Wins',
              style: GoogleFonts.poppins(
                fontSize: compact ? 20 : 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: brightness == Brightness.dark
                    ? AppTheme.homeTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: brightness == Brightness.dark
                    ? AppTheme.homeTextSecondary
                    : AppTheme.lightTextSecondary,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                'View all',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (surprises.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
            child: Text(
              'No resolved battles yet. Your first win will appear here.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: brightness == Brightness.dark
                    ? AppTheme.homeTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = surprises.take(4).toList();
              const spacing = 10.0;
              final tileWidth = (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: cards.map((surprise) {
                  final date = surprise.lastActivityAt ??
                      surprise.unlockedAt ??
                      surprise.createdAt;
                  final judgeName =
                      judgeNameForPersona(surprise.judgePersona);
                  return SizedBox(
                    width: tileWidth,
                    child: _WinCard(
                      title: judgeName,
                      dateText: '${date.month}/${date.day}',
                      compact: compact,
                      height: itemHeight,
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}

class _WinCard extends StatelessWidget {
  const _WinCard({
    required this.title,
    required this.dateText,
    required this.compact,
    required this.height,
  });

  final String title;
  final String dateText;
  final bool compact;
  final double height;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      height: height,
      padding:
          EdgeInsets.symmetric(horizontal: compact ? 12 : 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        color: brightness == Brightness.dark
            ? AppTheme.glassFill
            : Colors.white.withValues(alpha: 0.70),
        border: Border.all(
          color: brightness == Brightness.dark
              ? AppTheme.glassBorder
              : AppTheme.lightGlassBorder,
        ),
        boxShadow: AppTheme.elevation1(brightness),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 38 : 42,
            height: compact ? 38 : 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.ctaGoldA, AppTheme.ctaGoldB],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.premiumGold.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: const Color(0xFF4A2800),
              size: compact ? 18 : 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: brightness == Brightness.dark
                        ? AppTheme.homeTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateText,
                  style: GoogleFonts.inter(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w400,
                    color: brightness == Brightness.dark
                        ? AppTheme.homeTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
