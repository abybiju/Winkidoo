import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/character_chat/widgets/character_selector.dart';

/// Bottom input bar: character selector row + text field + send button.
class ChatInputBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

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
          const CharacterSelector(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: brightness == Brightness.dark
                        ? AppTheme.glassFillHover
                        : Colors.white.withValues(alpha: 0.80),
                    border: Border.all(
                      color: brightness == Brightness.dark
                          ? AppTheme.glassBorder
                          : AppTheme.lightGlassBorder,
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: brightness == Brightness.dark
                          ? AppTheme.homeTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        color: brightness == Brightness.dark
                            ? AppTheme.homeTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
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
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSending
                        ? AppTheme.primaryOrange.withValues(alpha: 0.4)
                        : AppTheme.primaryOrange,
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
                          size: 20,
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
