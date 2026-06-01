import 'dart:async';

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
import 'package:winkidoo/features/character_chat/widgets/typing_indicator.dart';
import 'package:winkidoo/models/character_chat_message.dart';
import 'package:winkidoo/models/character_preset.dart';
import 'package:winkidoo/models/chat_room.dart';
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
  List<TypingUser> _typingOthers = const [];
  Timer? _typingTimer;
  bool _selfNameResolved = false;

  @override
  void initState() {
    super.initState();
    _realtimeService = CharacterChatRealtimeService(Supabase.instance.client);
    final user = ref.read(currentUserProvider);
    _realtimeService.subscribe(
      widget.roomId,
      selfUid: user?.id ?? '',
      selfName: _fallbackSelfName(user),
      onMessage: (msg) {
        ref.read(chatMessagesProvider(widget.roomId).notifier).upsert(msg);
        _scrollToBottom();
      },
      onTypingChanged: (others) {
        if (!mounted) return;
        setState(() => _typingOthers = others);
      },
    );
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _realtimeService.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Best-effort self name before room members load (auth metadata / email).
  String _fallbackSelfName(User? user) {
    final meta = user?.userMetadata;
    final dn = meta?['display_name'] ?? meta?['full_name'] ?? meta?['name'];
    if (dn is String && dn.trim().isNotEmpty) return dn.trim();
    final email = user?.email;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'Someone';
  }

  /// Once room members load, push my real display name into presence so peers
  /// see the right name in the typing indicator.
  void _resolveSelfName(List<ChatRoomMember> members, String? myId) {
    if (_selfNameResolved || myId == null || members.isEmpty) return;
    for (final m in members) {
      if (m.userId == myId) {
        final name = m.displayName ?? m.email;
        if (name != null && name.isNotEmpty) {
          _selfNameResolved = true;
          _realtimeService.updateSelfName(name);
        }
        return;
      }
    }
  }

  void _onInputChanged(String _) {
    _realtimeService.setTyping(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 2500), () {
      _realtimeService.setTyping(false);
    });
  }

  String _typingLabel(List<TypingUser> others) {
    if (others.length == 1) return '${others.first.name} is typing';
    if (others.length == 2) {
      return '${others[0].name}, ${others[1].name} are typing';
    }
    return '${others[0].name}, ${others[1].name} +${others.length - 2} are typing';
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
    final notifier = ref.read(chatMessagesProvider(widget.roomId).notifier);

    // Typing stops the moment you send.
    _typingTimer?.cancel();
    _realtimeService.setTyping(false);

    // Optimistic local echo — show the bubble instantly.
    final tempId = 'temp-${DateTime.now().microsecondsSinceEpoch}';
    notifier.upsert(CharacterChatMessage(
      id: tempId,
      roomId: widget.roomId,
      senderId: user.id,
      originalContent: text,
      characterId: character.id,
      characterName: character.name,
      toneId: hasTone ? tone.id : null,
      isTransforming: needsTransform,
      createdAt: DateTime.now().toUtc(),
    ));
    _scrollToBottom();

    try {
      final inserted = await service.insertMessage(
        roomId: widget.roomId,
        senderId: user.id,
        originalContent: text,
        characterId: character.id,
        characterName: character.name,
        toneId: hasTone ? tone.id : null,
        isTransforming: needsTransform,
      );

      notifier.reconcile(tempId, inserted);
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
          notifier.upsert(
              await service.updateTransformedContent(inserted.id, transformed));
        } catch (e) {
          notifier.upsert(await service.markTransformFailed(inserted.id));
        }
      }
    } catch (e) {
      notifier.remove(tempId);
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

    // Members (real names) — used for the WhatsApp-style title and incoming
    // message labels. Receivers see real names, never personas/tones.
    final members = ref.watch(roomMembersProvider(widget.roomId)).value ?? [];
    _resolveSelfName(members, user?.id);
    String roomTitle;
    if (room == null) {
      roomTitle = 'Chat';
    } else if (room.isGroup) {
      roomTitle =
          (room.name != null && room.name!.isNotEmpty) ? room.name! : 'Group';
    } else {
      final others = members.where((m) => m.userId != user?.id).toList();
      roomTitle = others.isNotEmpty
          ? (others.first.displayName ?? others.first.email ?? 'Chat')
          : ((room.name != null && room.name!.isNotEmpty) ? room.name! : 'Chat');
    }
    String? senderNameFor(String id) {
      for (final m in members) {
        if (m.userId == id) return m.displayName ?? m.email;
      }
      return null;
    }

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

                        // Centered chat title (WhatsApp style) + persona selector.
                        // The title is the group/contact name (shown to everyone);
                        // the small "as <persona>" line below is the local user's
                        // own persona picker — visible only to them.
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                roomTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.01,
                                ),
                              ),
                              const SizedBox(height: 1),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _isPopoverOpen = !_isPopoverOpen),
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      tone.isNone
                                          ? 'as ${character.name.toLowerCase()}'
                                          : 'as ${character.name.toLowerCase()} · ${tone.name.toLowerCase()}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: accent,
                                      ),
                                    ),
                                    AnimatedRotation(
                                      turns: _isPopoverOpen ? 0.5 : 0,
                                      duration:
                                          const Duration(milliseconds: 240),
                                      child: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                            final isMine = msg.senderId == user?.id;
                            return ChatMessageBubble(
                              message: msg,
                              isMine: isMine,
                              senderName:
                                  isMine ? null : senderNameFor(msg.senderId),
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

                  // ── Typing indicator ──
                  if (_typingOthers.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TypingIndicator(label: _typingLabel(_typingOthers)),
                    ),

                  // ── Input bar ──
                  ChatInputBar(
                    controller: _textController,
                    onSend: _sendMessage,
                    isSending: _isSending,
                    onChanged: _onInputChanged,
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
