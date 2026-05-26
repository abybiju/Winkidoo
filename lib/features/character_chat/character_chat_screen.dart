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
import 'package:winkidoo/models/character_preset.dart';
import 'package:winkidoo/providers/ai_judge_provider.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/character_chat_provider.dart';
import 'package:winkidoo/services/character_chat_realtime_service.dart';
import 'package:winkidoo/services/api_rate_limiter.dart';
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
  bool _isPopoverOpen = false;

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

    final rl = ApiRateLimiter.checkAndRecord('ai_character_chat', user.id);
    if (!rl.allowed) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(rl.userMessage), backgroundColor: AppTheme.error),
        );
      }
      return;
    }

    final characterId = ref.read(selectedCharacterProvider);
    final characters = ref.read(availableCharactersProvider).value ?? [];
    final character = characters.firstWhere(
      (c) => c.id == characterId,
      orElse: () => CharacterChatService.builtInPresets.first,
    );

    final toneId = ref.read(selectedToneProvider);
    final tone = CharacterChatService.toneById(toneId);
    final hasTone = !tone.isNone;

    final isNormal = character.id == 'normal';
    final needsTransform = !isNormal || hasTone;
    final service = ref.read(characterChatServiceProvider);

    try {
      final messageId = await service.insertMessage(
        roomId: widget.roomId,
        senderId: user.id,
        originalContent: text,
        characterId: character.id,
        characterName: character.name,
        toneId: hasTone ? tone.id : null,
        isTransforming: needsTransform,
      );

      ref.invalidate(chatMessagesProvider(widget.roomId));
      _scrollToBottom();

      if (needsTransform) {
        try {
          final aiService = ref.read(aiJudgeServiceProvider);
          final transformed = await aiService.transformAsCharacter(
            originalText: text,
            characterSystemPrompt: isNormal ? '' : character.systemPrompt,
            characterName: isNormal ? 'Normal' : character.name,
            toneInstructions: hasTone ? tone.promptInstructions : null,
            toneName: hasTone ? tone.name : null,
          );
          await service.updateTransformedContent(messageId, transformed);
        } catch (e) {
          await service.markTransformFailed(messageId);
        }
      }

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
    final roomAsync = ref.watch(chatRoomProvider(widget.roomId));
    final user = ref.watch(currentUserProvider);
    final brightness = Theme.of(context).brightness;

    final messages = messagesAsync.value ?? [];
    final room = roomAsync.value;

    // Current persona
    final characterId = ref.watch(selectedCharacterProvider);
    final characters = ref.watch(availableCharactersProvider).value ?? [];
    final character = characters.isEmpty
        ? CharacterChatService.builtInPresets.first
        : characters.firstWhere(
            (c) => c.id == characterId,
            orElse: () => characters.first,
          );
    final accent = character.color ?? AppTheme.primaryOrange;

    // Current tone
    final toneId = ref.watch(selectedToneProvider);
    final tone = CharacterChatService.toneById(toneId);

    if (messages.isNotEmpty) _scrollToBottom();

    return Scaffold(
      body: CosmicBackground(
        showStars: true,
        glowColor: accent,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  // ── Header: back + persona pill + share ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.glassFill,
                              border: Border.all(color: AppTheme.glassBorder),
                            ),
                            child: const Icon(Icons.arrow_back_ios_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),

                        // Centered persona pill
                        Expanded(
                          child: Center(
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _isPopoverOpen = !_isPopoverOpen),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 40,
                                padding: const EdgeInsets.only(
                                    left: 6, right: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      accent.withValues(alpha: 0.20),
                                      accent.withValues(alpha: 0.07),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.40),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.20),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Avatar circle
                                    Container(
                                      width: 28,
                                      height: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          center:
                                              const Alignment(-0.3, -0.4),
                                          colors: [
                                            accent.withValues(alpha: 0.70),
                                            accent.withValues(alpha: 0.30),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                accent.withValues(alpha: 0.33),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        character.emoji.isNotEmpty
                                            ? character.emoji
                                            : character.name
                                                .substring(0, 1)
                                                .toUpperCase(),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Name + mood label
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          character.name.toLowerCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: accent,
                                            letterSpacing: -0.01,
                                            height: 1.1,
                                          ),
                                        ),
                                        if (!tone.isNone)
                                          Text(
                                            tone.name.toLowerCase(),
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 9,
                                              color: brightness ==
                                                      Brightness.dark
                                                  ? AppTheme.homeTextSecondary
                                                  : AppTheme
                                                      .lightTextSecondary,
                                              letterSpacing: 0.1,
                                              height: 1.3,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 6),
                                    // Chevron
                                    AnimatedRotation(
                                      turns: _isPopoverOpen ? 0.5 : 0,
                                      duration:
                                          const Duration(milliseconds: 240),
                                      child: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Share button
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

                  // ── Messages ──
                  Expanded(
                    child: messagesAsync.when(
                      data: (msgs) {
                        if (msgs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(PhosphorIconsFill.chatTeardropDots,
                                      size: 48,
                                      color: accent.withValues(alpha: 0.3)),
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
                          padding:
                              const EdgeInsets.fromLTRB(14, 8, 14, 12),
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

                  // ── Input bar ──
                  ChatInputBar(
                    controller: _textController,
                    onSend: _sendMessage,
                    isSending: _isSending,
                  ),
                ],
              ),

              // ── Popover overlay ──
              if (_isPopoverOpen) ...[
                // Backdrop
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPopoverOpen = false),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // Popover dropdown
                Positioned(
                  top: 62,
                  left: 16,
                  right: 16,
                  child: _PersonaPopover(
                    characters: characters,
                    selectedId: characterId,
                    accent: accent,
                    brightness: brightness,
                    onSelect: (id) {
                      ref.read(selectedCharacterProvider.notifier).state = id;
                      setState(() => _isPopoverOpen = false);
                    },
                    onCreateTap: () {
                      setState(() => _isPopoverOpen = false);
                      context.push('/shell/create-judge',
                          extra: {'defaultUseFor': 'chat'});
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dropdown popover showing persona avatars in a scrollable row.
class _PersonaPopover extends StatelessWidget {
  const _PersonaPopover({
    required this.characters,
    required this.selectedId,
    required this.accent,
    required this.brightness,
    required this.onSelect,
    required this.onCreateTap,
  });

  final List<CharacterPreset> characters;
  final String selectedId;
  final Color accent;
  final Brightness brightness;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              brightness == Brightness.dark
                  ? const Color(0xFF1A0D3A)
                  : const Color(0xFFF5F0FF),
              brightness == Brightness.dark
                  ? const Color(0xFF050310)
                  : const Color(0xFFEDE8F5),
            ],
          ),
          border: Border.all(
            color: brightness == Brightness.dark
                ? AppTheme.glassBorder
                : AppTheme.lightGlassBorder,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 40,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PERSONA',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
                color: brightness == Brightness.dark
                    ? AppTheme.homeTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: characters.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  // "+" create button
                  if (index == characters.length) {
                    return GestureDetector(
                      onTap: onCreateTap,
                      child: SizedBox(
                        width: 56,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.glassFill,
                                border: Border.all(
                                  color: AppTheme.glassBorder,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Icon(
                                PhosphorIconsBold.plus,
                                size: 14,
                                color: brightness == Brightness.dark
                                    ? AppTheme.homeTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'create',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                color: brightness == Brightness.dark
                                    ? AppTheme.homeTextSecondary
                                    : AppTheme.lightTextSecondary,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final char = characters[index];
                  final isActive = char.id == selectedId;
                  final charColor = char.color ?? AppTheme.primaryOrange;

                  return GestureDetector(
                    onTap: () => onSelect(char.id),
                    child: SizedBox(
                      width: 56,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: isActive
                                  ? charColor.withValues(alpha: 0.13)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isActive
                                    ? charColor
                                    : Colors.transparent,
                              ),
                            ),
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  center: const Alignment(-0.3, -0.4),
                                  colors: [
                                    charColor.withValues(alpha: 0.80),
                                    charColor.withValues(alpha: 0.30),
                                  ],
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: charColor
                                              .withValues(alpha: 0.33),
                                          blurRadius: 12,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                char.emoji.isNotEmpty
                                    ? char.emoji
                                    : char.name
                                        .substring(0, 1)
                                        .toUpperCase(),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            char.name.length > 8
                                ? '${char.name.substring(0, 7)}…'
                                : char.name,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              color: isActive
                                  ? charColor
                                  : (brightness == Brightness.dark
                                      ? AppTheme.homeTextSecondary
                                      : AppTheme.lightTextSecondary),
                              letterSpacing: 0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
