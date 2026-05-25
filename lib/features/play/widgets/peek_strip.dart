import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/glass_container.dart';
import 'package:winkidoo/features/play/play_card_stack_state.dart';

class PeekStrip extends StatelessWidget {
  const PeekStrip({
    super.key,
    required this.meta,
    required this.onTap,
  });

  final PlayCardMeta meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GlassContainer(
      onTap: onTap,
      tint: meta.accentColor,
      glowEdge: true,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: meta.accentColor.withValues(alpha: 0.18),
            ),
            child: Icon(
              meta.icon,
              size: 17,
              color: meta.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              meta.label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: brightness == Brightness.dark
                    ? AppTheme.textPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: meta.accentColor.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
