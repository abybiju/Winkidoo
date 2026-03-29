import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/judge_pack.dart';
import 'package:winkidoo/providers/pack_provider.dart';

class PackBannerCard extends ConsumerWidget {
  const PackBannerCard({
    super.key,
    required this.onExplorePacks,
    this.compact = false,
  });

  final VoidCallback onExplorePacks;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePackAsync = ref.watch(coupleActivePackProvider);
    final allPacksAsync = ref.watch(activePacksProvider);

    return activePackAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (activePack) {
        if (activePack != null) {
          return _ActivePackBanner(
            pack: activePack,
            onTap: onExplorePacks,
            compact: compact,
          );
        }
        // No active pack — show explore CTA if packs exist
        return allPacksAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (packs) {
            if (packs.isEmpty) return const SizedBox.shrink();
            return _ExplorePacksBanner(
              onTap: onExplorePacks,
              compact: compact,
            );
          },
        );
      },
    );
  }
}

class _ActivePackBanner extends StatelessWidget {
  const _ActivePackBanner({
    required this.pack,
    required this.onTap,
    this.compact = false,
  });

  final JudgePack pack;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.vaultHeroGradient(brightness),
          ),
          border: Border.all(
            color: AppTheme.primaryOrange.withValues(alpha: 0.25),
          ),
          boxShadow: AppTheme.elevation2(brightness),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.battleGradientA, AppTheme.battleGradientB],
                ),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pack.name,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 14 : 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.homeTextPrimary,
                    ),
                  ),
                  if (pack.bpMultiplier > 1.0 ||
                      (pack.isSeasonal && pack.daysRemaining >= 0))
                    Text(
                      [
                        if (pack.bpMultiplier > 1.0)
                          '${pack.bpMultiplier}x BP',
                        if (pack.isSeasonal && pack.daysRemaining >= 0)
                          '${pack.daysRemaining}d left',
                      ].join(' · '),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.primaryOrangeLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplorePacksBanner extends StatelessWidget {
  const _ExplorePacksBanner({
    required this.onTap,
    this.compact = false,
  });

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          color: brightness == Brightness.dark
              ? AppTheme.glassFill
              : AppTheme.lightGlassFill,
          border: Border.all(
            color: brightness == Brightness.dark
                ? AppTheme.glassBorder
                : AppTheme.lightGlassBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Explore Battle Packs',
                style: GoogleFonts.inter(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.homeTextPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
