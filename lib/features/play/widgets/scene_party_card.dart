import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/scene_party_provider.dart';

/// Play-tab accordion card for Scene Party (themed group roleplay rooms).
class ScenePartyCard extends ConsumerWidget {
  const ScenePartyCard({
    super.key,
    required this.brightness,
    required this.isCompact,
    required this.onTap,
  });

  final Brightness brightness;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(scenePacksProvider);
    final emojis = packsAsync.value
            ?.map((p) => p.emoji)
            .whereType<String>()
            .take(6)
            .join('  ') ??
        '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isCompact ? 14 : 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: brightness == Brightness.dark
              ? AppTheme.glassFill
              : Colors.white.withValues(alpha: 0.70),
          border: Border.all(
            color: brightness == Brightness.dark
                ? AppTheme.glassBorderOrange
                : AppTheme.lightGlassBorder,
          ),
          boxShadow: AppTheme.elevation1(brightness),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppTheme.gold.withValues(alpha: 0.15),
              ),
              child: const Icon(
                PhosphorIconsFill.maskHappy,
                color: AppTheme.gold,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scene Party',
                    style: GoogleFonts.poppins(
                      fontSize: isCompact ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      color: brightness == Brightness.dark
                          ? AppTheme.homeTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Claim a character. Improvise the story. The AI directs.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: brightness == Brightness.dark
                          ? AppTheme.homeTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (emojis.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      emojis,
                      style: const TextStyle(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.gold, size: 22),
          ],
        ),
      ),
    );
  }
}
