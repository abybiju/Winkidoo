import 'package:flutter/material.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/shimmer_effect.dart';

/// Placeholder row for battle chat loading state with shimmer sweep.
class SkeletonMessageRow extends StatelessWidget {
  const SkeletonMessageRow({
    super.key,
    this.alignRight = false,
  });

  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final baseColor = brightness == Brightness.dark
        ? AppTheme.glassFillHover
        : const Color(0x0F000000);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: ShimmerEffect(
          child: Container(
            width: 220,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: brightness == Brightness.dark
                  ? AppTheme.glassFill
                  : Colors.white.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: brightness == Brightness.dark
                    ? AppTheme.glassBorderSubtle
                    : AppTheme.lightGlassBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 140,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
