import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/character_chat/widgets/tone_selector.dart';
import 'package:winkidoo/providers/character_chat_provider.dart';
import 'package:winkidoo/services/character_chat_service.dart';

/// Bottom input bar: mood rail + persona-tinted text field + send button.
class ChatInputBar extends ConsumerWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isSending,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;

    final characterId = ref.watch(selectedCharacterProvider);
    final characters = ref.watch(availableCharactersProvider).value ?? [];
    final character = characters.isEmpty
        ? CharacterChatService.builtInPresets.first
        : characters.firstWhere(
            (c) => c.id == characterId,
            orElse: () => characters.first,
          );

    final accent = character.color ?? AppTheme.primaryOrange;

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? AppTheme.footerBase.withValues(alpha: 0.95)
            : const Color(0xFFF0ECF8).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: brightness == Brightness.dark
                ? AppTheme.glassBorder
                : AppTheme.lightGlassBorder,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mood rail only — character selection is in the header pill
          ToneSelector(personaColor: accent),
          const SizedBox(height: 8),
          // Persona-tinted composer
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: brightness == Brightness.dark
                        ? const Color(0xFF0F0828).withValues(alpha: 0.70)
                        : Colors.white.withValues(alpha: 0.80),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.14),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: brightness == Brightness.dark
                          ? AppTheme.homeTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: character.id == 'normal'
                          ? 'Type a message...'
                          : 'say it as ${character.name}...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: brightness == Brightness.dark
                            ? AppTheme.homeTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isSending ? null : onSend,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSending
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [accent, accent.withValues(alpha: 0.67)],
                          ),
                    color: isSending
                        ? accent.withValues(alpha: 0.4)
                        : null,
                    boxShadow: isSending
                        ? null
                        : [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.40),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          PhosphorIconsFill.paperPlaneTilt,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
