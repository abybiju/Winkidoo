import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/character_chat_message.dart';

/// A single chat message bubble with character badge and tap-to-reveal.
class ChatMessageBubble extends StatefulWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  final CharacterChatMessage message;
  final bool isMine;

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isMine = widget.isMine;
    final brightness = Theme.of(context).brightness;

    final hasTransform =
        msg.transformedContent != null && msg.transformedContent!.isNotEmpty;
    final displayText =
        _showOriginal ? msg.originalContent : msg.displayContent;
    final isTransforming = msg.isTransforming;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Character badge
              if (!msg.isNormal)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    'as ${msg.characterName}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryOrange.withValues(alpha: 0.7),
                    ),
                  ),
                ),

              // Message bubble
              GestureDetector(
                onTap: hasTransform && isMine
                    ? () => setState(() => _showOriginal = !_showOriginal)
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                    color: isMine
                        ? AppTheme.primaryOrange.withValues(alpha: 0.18)
                        : (brightness == Brightness.dark
                            ? AppTheme.glassFillHover
                            : Colors.white.withValues(alpha: 0.80)),
                    border: Border.all(
                      color: isMine
                          ? AppTheme.primaryOrange.withValues(alpha: 0.25)
                          : (brightness == Brightness.dark
                              ? AppTheme.glassBorder
                              : AppTheme.lightGlassBorder),
                    ),
                  ),
                  child: isTransforming
                      ? _TransformingIndicator(
                          characterName: msg.characterName,
                          brightness: brightness,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayText,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                                color: brightness == Brightness.dark
                                    ? AppTheme.homeTextPrimary
                                    : AppTheme.lightTextPrimary,
                              ),
                            ),
                            // "Tap to see original" hint
                            if (hasTransform && isMine) ...[
                              const SizedBox(height: 4),
                              Text(
                                _showOriginal
                                    ? 'Tap to see transformed'
                                    : 'Tap to see original',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryOrange
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransformingIndicator extends StatefulWidget {
  const _TransformingIndicator({
    required this.characterName,
    required this.brightness,
  });

  final String characterName;
  final Brightness brightness;

  @override
  State<_TransformingIndicator> createState() => _TransformingIndicatorState();
}

class _TransformingIndicatorState extends State<_TransformingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.4 + (0.6 * _controller.value);
        return Opacity(
          opacity: opacity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Transforming as ${widget.characterName}...',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: widget.brightness == Brightness.dark
                      ? AppTheme.homeTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
