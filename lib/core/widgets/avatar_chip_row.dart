import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          final baseColor = item.color ?? const Color(0xFFFFB649);
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
                            const Color(0xFFE85D93)
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
                            color: const Color(0xFFFFC52C),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFE7A900)),
                          ),
                          child: Text(
                            'New!',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: const Color(0xFF5A2C00),
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
                            color: Color(0xFFFFD600),
                          ),
                          child: Text(
                            item.badge!,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: const Color(0xFF5A2C00),
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
