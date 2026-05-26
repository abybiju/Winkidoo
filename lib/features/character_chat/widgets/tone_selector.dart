import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/character_chat_provider.dart';
import 'package:winkidoo/services/character_chat_service.dart';

/// Horizontal scrollable chip selector for picking a tone/mood overlay.
/// Active chips tint with [personaColor] to match the selected persona.
class ToneSelector extends ConsumerWidget {
  const ToneSelector({super.key, this.personaColor});

  final Color? personaColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedToneProvider);
    final brightness = Theme.of(context).brightness;
    final accent = personaColor ?? AppTheme.primaryOrange;

    final tones = CharacterChatService.builtInTones
        .where((t) => !t.isNone)
        .toList();

    return SizedBox(
      height: 30,
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
              ref.read(selectedToneProvider.notifier).state =
                  isSelected ? 'none' : tone.id;
            },
            child: AnimatedContainer(
              duration: AppTheme.microDuration,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.20),
                          accent.withValues(alpha: 0.09),
                        ],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (brightness == Brightness.dark
                        ? AppTheme.glassFill
                        : Colors.white.withValues(alpha: 0.50)),
                border: Border.all(
                  color: isSelected
                      ? accent
                      : (brightness == Brightness.dark
                          ? AppTheme.glassBorder
                          : AppTheme.lightGlassBorder),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.27),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tone.emoji,
                      style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? null : Colors.white54)),
                  const SizedBox(width: 5),
                  Text(
                    tone.name,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? accent
                          : (brightness == Brightness.dark
                              ? AppTheme.homeTextPrimary
                              : AppTheme.lightTextPrimary),
                      letterSpacing: -0.005,
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
