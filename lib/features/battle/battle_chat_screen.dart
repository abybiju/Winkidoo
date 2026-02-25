import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/battle/reveal_screen.dart';
import 'package:winkidoo/models/battle_message.dart';
import 'package:winkidoo/models/judge_response.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/providers/ai_judge_provider.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/battle_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/providers/winks_provider.dart';
import 'package:winkidoo/services/battle_realtime_service.dart';

class BattleChatScreen extends ConsumerStatefulWidget {
  const BattleChatScreen({super.key, required this.surpriseId});

  final String surpriseId;

  @override
  ConsumerState<BattleChatScreen> createState() => _BattleChatScreenState();
}

class _BattleChatScreenState extends ConsumerState<BattleChatScreen> {
  final _textController = TextEditingController();
  BattleRealtimeService? _realtime;
  bool _isSending = false;
  bool _navigatedToVerdict = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _realtime = BattleRealtimeService(ref.read(supabaseClientProvider));
      _realtime!.subscribe(widget.surpriseId, () {
        ref.invalidate(battleMessagesProvider(widget.surpriseId));
      });
    });
  }

  @override
  void dispose() {
    _realtime?.dispose();
    _textController.dispose();
    super.dispose();
  }

  BattleMessage? _verdictMessage(List<BattleMessage> messages) {
    try {
      return messages.lastWhere((m) => m.isVerdict);
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendMessage(String senderType, String content) async {
    if (content.trim().isEmpty) return;
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    setState(() => _isSending = true);
    _textController.clear();

    final client = ref.read(supabaseClientProvider);
    final surprise = await ref.read(surpriseByIdProvider(widget.surpriseId).future);
    if (surprise == null) {
      setState(() => _isSending = false);
      return;
    }

    try {
      await client.from('battle_messages').insert({
        'id': const Uuid().v4(),
        'surprise_id': widget.surpriseId,
        'sender_type': senderType,
        'sender_id': userId,
        'content': content.trim(),
        'is_verdict': false,
      });

      ref.invalidate(battleMessagesProvider(widget.surpriseId));
      await Future.delayed(const Duration(milliseconds: 300));

      final messages = await ref.read(battleMessagesProvider(widget.surpriseId).future);
      final ai = ref.read(aiJudgeServiceProvider);
      final surpriseContextHint = surprise.unlockMethod.isNotEmpty
          ? 'Surprise type: ${surprise.unlockMethod}'
          : 'romantic surprise';
      final howToImpressHint = _howToImpressHintForSurprise(surprise);
      final judgeResponse = await ai.judgeChat(
        persona: surprise.judgePersona,
        difficultyLevel: surprise.difficultyLevel,
        messages: messages,
        surpriseContextHint: surpriseContextHint,
        howToImpressHint: howToImpressHint,
      );

      final isVerdictNow = judgeResponse.isVerdict;

      await client.from('battle_messages').insert({
        'id': const Uuid().v4(),
        'surprise_id': widget.surpriseId,
        'sender_type': 'judge',
        'sender_id': null,
        'content': judgeResponse.commentary,
        'is_verdict': isVerdictNow,
        'verdict_score': isVerdictNow ? judgeResponse.score : null,
        'verdict_unlocked': isVerdictNow ? judgeResponse.isUnlocked : null,
      });

      if (isVerdictNow && judgeResponse.isUnlocked) {
        await client.from('surprises').update({
          'is_unlocked': true,
          'unlocked_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', widget.surpriseId);
      }

      ref.invalidate(battleMessagesProvider(widget.surpriseId));
      ref.invalidate(surpriseByIdProvider(widget.surpriseId));
      ref.invalidate(surprisesListProvider);

      if (isVerdictNow && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RevealScreen(
              surpriseId: widget.surpriseId,
              judgeResponse: judgeResponse,
              creatorId: surprise.creatorId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _buyHint(Surprise surprise) async {
    final ok = await spendWinks(
      ref,
      AppConstants.hintCostWinks,
      type: 'hint',
      description: 'Hint for surprise',
    );
    if (!ok || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough Winks (need 5 😉)'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }
    setState(() => _isSending = true);
    try {
      final ai = ref.read(aiJudgeServiceProvider);
      final hint = await ai.getHint(
        persona: surprise.judgePersona,
        difficultyLevel: surprise.difficultyLevel,
        surpriseContextHint: surprise.unlockMethod.isNotEmpty
            ? 'Surprise type: ${surprise.unlockMethod}'
            : null,
      );
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Judge\'s hint'),
          content: Text(hint),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _buyInstantUnlock(Surprise surprise) async {
    final ok = await spendWinks(
      ref,
      AppConstants.instantUnlockCostWinks,
      type: 'instant_unlock',
      description: 'Instant unlock',
    );
    if (!ok || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough Winks (need 50 😉)'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('surprises').update({
        'is_unlocked': true,
        'unlocked_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', widget.surpriseId);
      ref.invalidate(surpriseByIdProvider(widget.surpriseId));
      ref.invalidate(surprisesListProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RevealScreen(
            surpriseId: widget.surpriseId,
            judgeResponse: JudgeResponse(
              score: 0,
              isUnlocked: true,
              commentary: 'Unlocked with Winks! 🎉',
              hint: null,
              moodEmoji: '😉',
              isVerdict: true,
            ),
            creatorId: surprise.creatorId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  /// Derives a short "how to impress" hint from surprise (unlock method; MVP1 is message-only).
  String? _howToImpressHintForSurprise(Surprise surprise) {
    switch (surprise.unlockMethod) {
      case AppConstants.unlockPersuade:
        return 'For this message surprise: try a voice note, a really personal line, or a little grand gesture.';
      case AppConstants.unlockCollaborate:
        return 'Show teamwork — both of you chip in with something thoughtful.';
      default:
        return 'Try a voice note or a personal message.';
    }
  }

  String _personaLabel(String id) {
    switch (id) {
      case AppConstants.personaSassyCupid:
        return 'Sassy Cupid';
      case AppConstants.personaPoeticRomantic:
        return 'Poetic Romantic';
      case AppConstants.personaChaosGremlin:
        return 'Chaos Gremlin';
      case AppConstants.personaTheEx:
        return 'The Ex';
      case AppConstants.personaDrLove:
        return 'Dr. Love';
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final surpriseAsync = ref.watch(surpriseByIdProvider(widget.surpriseId));
    final messagesAsync = ref.watch(battleMessagesProvider(widget.surpriseId));
    final userId = ref.watch(currentUserProvider)?.id;

    return surpriseAsync.when(
      data: (surprise) {
        if (surprise == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Battle')),
            body: const Center(child: Text('Surprise not found')),
          );
        }
        final isCreator = userId == surprise.creatorId;

        return Scaffold(
          appBar: AppBar(
            title: Text('Judge: ${_personaLabel(surprise.judgePersona)}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.backgroundStart, AppTheme.backgroundEnd],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  messagesAsync.when(
                    data: (messages) {
                      final verdict = _verdictMessage(messages);
                      if (verdict != null && mounted && !_navigatedToVerdict) {
                        _navigatedToVerdict = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          final judgeResponse = JudgeResponse(
                            score: verdict.verdictScore ?? 0,
                            isUnlocked: verdict.verdictUnlocked ?? false,
                            commentary: verdict.content,
                            hint: null,
                            moodEmoji: '⚖️',
                          );
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => RevealScreen(
                                surpriseId: widget.surpriseId,
                                judgeResponse: judgeResponse,
                                creatorId: surprise.creatorId,
                              ),
                            ),
                          );
                        });
                      }

                      final status = verdict != null
                          ? 'Verdict in — tap Back to vault'
                          : 'Live — convince the judge!';

                      return Expanded(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            if (verdict == null && !isCreator)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Semantics(
                                      label:
                                          'Get a hint for ${AppConstants.hintCostWinks} Winks',
                                      button: true,
                                      child: OutlinedButton.icon(
                                        onPressed: _isSending
                                            ? null
                                            : () => _buyHint(surprise),
                                        icon: Text(
                                            '${AppConstants.hintCostWinks} 😉'),
                                        label: const Text('Get hint'),
                                      ),
                                    ),
                                    Semantics(
                                      label:
                                          'Unlock now for ${AppConstants.instantUnlockCostWinks} Winks',
                                      button: true,
                                      child: OutlinedButton.icon(
                                        onPressed: _isSending
                                            ? null
                                            : () => _buyInstantUnlock(surprise),
                                        icon: Text(
                                            '${AppConstants.instantUnlockCostWinks} 😉'),
                                        label: const Text('Unlock now'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: messages.length,
                                itemBuilder: (_, i) {
                                  final m = messages[i];
                                  return _ChatBubble(
                                    message: m,
                                    isMe: (m.isFromSeeker && !isCreator) ||
                                        (m.isFromCreator && isCreator),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _textController,
                                      decoration: const InputDecoration(
                                        hintText: 'Type your argument...',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: 2,
                                      enabled: verdict == null && !_isSending,
                                      onSubmitted: (_) {
                                        if (verdict == null && !_isSending) {
                                          final type =
                                              isCreator ? 'creator' : 'seeker';
                                          _sendMessage(
                                            type,
                                            _textController.text,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filled(
                                    onPressed: (verdict == null && !_isSending)
                                        ? () {
                                            final type = isCreator
                                                ? 'creator'
                                                : 'seeker';
                                            _sendMessage(
                                              type,
                                              _textController.text,
                                            );
                                          }
                                        : null,
                                    icon: _isSending
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.send),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    error: (e, _) => Expanded(
                      child: Center(
                        child: Text(
                          'Could not load messages',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Battle')),
        body: Center(child: Text('Error: $e', style: TextStyle(color: AppTheme.error))),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isMe});

  final BattleMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    if (message.isFromJudge) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '⚖️ Judge',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.content,
                  style: GoogleFonts.caveat(
                    fontSize: 18,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (message.isVerdict && message.verdictScore != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Score: ${message.verdictScore}/100 • '
                    '${message.verdictUnlocked == true ? "Unlocked!" : "Denied"}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primary : AppTheme.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.content,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
