import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

class AvatarChipData {
  const AvatarChipData({
    required this.label,
    this.badge,
    this.color,
    this.isNew = false,
  });

  final String label;
  final String? badge;
  final Color? color;
  final bool isNew;
}

class AvatarChipRow extends StatelessWidget {
  const AvatarChipRow({
    super.key,
    required this.items,
  });

  final List<AvatarChipData> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final baseColor = item.color ?? AppTheme.primaryOrangeLight;
          return SizedBox(
            width: 70,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            baseColor.withValues(alpha: 0.85),
                            AppTheme.primaryOrange
                          ],
                        ),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.label.characters.first.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    if (item.isNew)
                      Positioned(
                        left: -4,
                        bottom: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.premiumAmber,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppTheme.primaryOrangeDark),
                          ),
                          child: Text(
                            'New!',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: const Color(0xFF3D1800),
                            ),
                          ),
                        ),
                      ),
                    if (item.badge != null)
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.premiumAmber,
                          ),
                          child: Text(
                            item.badge!,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: const Color(0xFF3D1800),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
