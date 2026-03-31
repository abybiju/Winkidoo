import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/character_chat_provider.dart';

/// Horizontal scrollable chip selector for picking a character persona.
class CharacterSelector extends ConsumerWidget {
  const CharacterSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charactersAsync = ref.watch(availableCharactersProvider);
    final selectedId = ref.watch(selectedCharacterProvider);
    final brightness = Theme.of(context).brightness;

    final characters = charactersAsync.value ?? [];
    if (characters.isEmpty) return const SizedBox(height: 48);

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: characters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final char = characters[index];
          final isSelected = char.id == selectedId;

          return GestureDetector(
            onTap: () =>
                ref.read(selectedCharacterProvider.notifier).state = char.id,
            child: AnimatedContainer(
              duration: AppTheme.microDuration,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                color: isSelected
                    ? AppTheme.primaryOrange.withValues(alpha: 0.20)
                    : (brightness == Brightness.dark
                        ? AppTheme.glassFill
                        : Colors.white.withValues(alpha: 0.50)),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryOrange
                      : (brightness == Brightness.dark
                          ? AppTheme.glassBorder
                          : AppTheme.lightGlassBorder),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (char.emoji.isNotEmpty) ...[
                    Text(char.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    char.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primaryOrange
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
