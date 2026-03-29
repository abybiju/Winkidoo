import 'package:flutter/material.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/shimmer_effect.dart';

/// Shimmer skeleton matching the tall home card shape (dare, mini-game, etc.).
class SkeletonHomeCard extends StatelessWidget {
  const SkeletonHomeCard({super.key, this.height = 180});

  final double height;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final baseColor = brightness == Brightness.dark
        ? AppTheme.glassFillHover
        : const Color(0x0F000000);

    return ShimmerEffect(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? AppTheme.glassFill
              : Colors.white.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: brightness == Brightness.dark
                ? AppTheme.glassBorderSubtle
                : AppTheme.lightGlassBorder,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 18,
                    width: 160,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 36,
                    width: 130,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 9,
              child: Container(
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small shimmer skeleton matching the banner card shape (pack, campaign).
class SkeletonBannerCard extends StatelessWidget {
  const SkeletonBannerCard({super.key, this.height = 56});

  final double height;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final baseColor = brightness == Brightness.dark
        ? AppTheme.glassFillHover
        : const Color(0x0F000000);

    return ShimmerEffect(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? AppTheme.glassFill
              : Colors.white.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: brightness == Brightness.dark
                ? AppTheme.glassBorderSubtle
                : AppTheme.lightGlassBorder,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: baseColor,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
