import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/features/character_chat/widgets/chat_input_bar.dart';
import 'package:winkidoo/features/character_chat/widgets/chat_message_bubble.dart';
import 'package:winkidoo/providers/ai_judge_provider.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/character_chat_provider.dart';
import 'package:winkidoo/services/character_chat_realtime_service.dart';
import 'package:winkidoo/services/character_chat_service.dart';

class CharacterChatScreen extends ConsumerStatefulWidget {
  const CharacterChatScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<CharacterChatScreen> createState() =>
      _CharacterChatScreenState();
}

class _CharacterChatScreenState extends ConsumerState<CharacterChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late final CharacterChatRealtimeService _realtimeService;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _realtimeService =
        CharacterChatRealtimeService(Supabase.instance.client);
    _realtimeService.subscribe(widget.roomId, () {
      ref.invalidate(chatMessagesProvider(widget.roomId));
    });
  }

  @override
  void dispose() {
    _realtimeService.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isSending = false);
      return;
    }

    final characterId = ref.read(selectedCharacterProvider);
    final characters = ref.read(availableCharactersProvider).value ?? [];
    final character = characters.firstWhere(
      (c) => c.id == characterId,
      orElse: () => CharacterChatService.builtInPresets.first,
    );

    final isNormal = character.id == 'normal';
    final service = ref.read(characterChatServiceProvider);

    try {
      // Step 1: Insert message immediately (optimistic)
      final messageId = await service.insertMessage(
        roomId: widget.roomId,
        senderId: user.id,
        originalContent: text,
        characterId: character.id,
        characterName: character.name,
        isTransforming: !isNormal,
      );

      // Refresh messages to show the new one
      ref.invalidate(chatMessagesProvider(widget.roomId));
      _scrollToBottom();

      // Step 2: Transform if not normal
      if (!isNormal) {
        try {
          final aiService = ref.read(aiJudgeServiceProvider);
          final transformed = await aiService.transformAsCharacter(
            originalText: text,
            characterSystemPrompt: character.systemPrompt,
            characterName: character.name,
          );
          await service.updateTransformedContent(messageId, transformed);
        } catch (e) {
          // Gemini failed — fall back to original text
          await service.markTransformFailed(messageId);
        }
      }

      // Realtime will pick up the update, but also invalidate locally
      ref.invalidate(chatMessagesProvider(widget.roomId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.roomId));
    final membersAsync = ref.watch(roomMembersProvider(widget.roomId));
    final roomAsync = ref.watch(chatRoomProvider(widget.roomId));
    final user = ref.watch(currentUserProvider);
    final brightness = Theme.of(context).brightness;

    final messages = messagesAsync.value ?? [];
    final memberCount = membersAsync.value?.length ?? 0;
    final room = roomAsync.value;

    // Auto-scroll when new messages arrive
    if (messages.isNotEmpty) _scrollToBottom();

    return Scaffold(
      body: CosmicBackground(
        showStars: true,
        glowColor: AppTheme.primaryOrange,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Character Chat',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: brightness == Brightness.dark
                                  ? AppTheme.homeTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                          Text(
                            '$memberCount members',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: brightness == Brightness.dark
                                  ? AppTheme.homeTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Share invite code
                    GestureDetector(
                      onTap: () {
                        final code = room?.inviteCode;
                        if (code == null) return;
                        HapticFeedback.lightImpact();
                        Clipboard.setData(ClipboardData(text: code));
                        SharePlus.instance.share(
                          ShareParams(
                            text:
                                'Join my Character Chat on Winkidoo! Use invite code: $code',
                          ),
                        );
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.glassFill,
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: const Icon(PhosphorIconsBold.shareNetwork,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // Message list
              Expanded(
                child: messagesAsync.when(
                  data: (msgs) {
                    if (msgs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIconsFill.chatTeardropDots,
                                  size: 48,
                                  color: AppTheme.primaryOrange
                                      .withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text(
                                'Send the first message!\nPick a character and type anything.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: brightness == Brightness.dark
                                      ? AppTheme.homeTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                      itemCount: msgs.length,
                      itemBuilder: (context, index) {
                        final msg = msgs[index];
                        return ChatMessageBubble(
                          message: msg,
                          isMine: msg.senderId == user?.id,
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryOrange),
                  ),
                  error: (_, __) => Center(
                    child: Text(
                      'Failed to load messages',
                      style: GoogleFonts.inter(
                          color: AppTheme.homeTextSecondary),
                    ),
                  ),
                ),
              ),

              // Input bar
              ChatInputBar(
                controller: _textController,
                onSend: _sendMessage,
                isSending: _isSending,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
