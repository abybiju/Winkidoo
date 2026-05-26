import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/character_chat_provider.dart';
import 'package:winkidoo/services/character_chat_service.dart';

/// Horizontal scrollable chip selector for picking a tone/mood overlay.
class ToneSelector extends ConsumerWidget {
  const ToneSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedToneProvider);
    final brightness = Theme.of(context).brightness;

    // Skip the "none" entry — it's the default / deselected state.
    final tones = CharacterChatService.builtInTones
        .where((t) => !t.isNone)
        .toList();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: tones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final tone = tones[index];
          final isSelected = tone.id == selectedId;

          return GestureDetector(
            onTap: () {
              // Tap again to deselect.
              ref.read(selectedToneProvider.notifier).state =
                  isSelected ? 'none' : tone.id;
            },
            child: AnimatedContainer(
              duration: AppTheme.microDuration,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                color: isSelected
                    ? tone.color.withValues(alpha: 0.20)
                    : (brightness == Brightness.dark
                        ? AppTheme.glassFill
                        : Colors.white.withValues(alpha: 0.50)),
                border: Border.all(
                  color: isSelected
                      ? tone.color
                      : (brightness == Brightness.dark
                          ? AppTheme.glassBorder
                          : AppTheme.lightGlassBorder),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tone.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    tone.name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? tone.color
                          : (brightness == Brightness.dark
                              ? AppTheme.homeTextPrimary
                              : AppTheme.lightTextPrimary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
