import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/core/utils/battle_math.dart';
import 'package:winkidoo/core/widgets/error_screen.dart';
import 'package:winkidoo/core/widgets/skeleton_message_row.dart';
import 'package:winkidoo/models/battle_message.dart';
import 'package:winkidoo/models/judge.dart';
import 'package:winkidoo/models/judge_response.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/providers/ai_judge_provider.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/battle_provider.dart';
import 'package:winkidoo/providers/judges_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/providers/user_profile_provider.dart';
import 'package:winkidoo/providers/winks_provider.dart';
import 'package:winkidoo/features/battle/persuasion_meter.dart';
import 'package:winkidoo/features/battle/pre_battle_tease.dart';
import 'package:winkidoo/services/battle_realtime_service.dart';
import 'package:winkidoo/services/battle_sound_service.dart';
import 'package:winkidoo/services/judge_memory_service.dart';
import 'package:winkidoo/providers/couple_provider.dart';

class BattleChatScreen extends ConsumerStatefulWidget {
  const BattleChatScreen({super.key, required this.surpriseId});

  final String surpriseId;

  @override
  ConsumerState<BattleChatScreen> createState() => _BattleChatScreenState();
}

class _BattleChatScreenState extends ConsumerState<BattleChatScreen> {
  final _textController = TextEditingController();
  BattleRealtimeService? _realtime;
  BattleSoundService? _soundService;
  bool _isSending = false;
  bool _navigatedToVerdict = false;
  bool _playedUnlockSound = false;

  // For emotional UX: detect resistance increase (vault reinforced) and fatigue weakening
  int? _lastResistanceScore;
  int? _lastFatigueLevel;
  int? _lastEffectiveResistance;
  final List<String> _systemMessages = [];
  int _pulseResistanceTrigger = 0;
  int _flickerResistanceTrigger = 0;
  String? _lastSystemMessageText;
  DateTime? _lastSystemMessageAt;
  bool _showTease = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _realtime = BattleRealtimeService(ref.read(supabaseClientProvider));
      if (_soundService == null)
        _soundService =
            BattleSoundService(); // Once per screen lifecycle; rebuilds do not recreate
      _realtime!.subscribe(
        widget.surpriseId,
        () {
          ref.invalidate(battleMessagesProvider(widget.surpriseId));
        },
        onSurpriseChanged: _onSurpriseRowChanged,
      );
    });
  }

  void _onSurpriseRowChanged(PostgresChangePayload payload) {
    if (!mounted) return;
    final newRecord = payload.newRecord;
    if (newRecord == null) return;

    ref.invalidate(surpriseByIdProvider(widget.surpriseId));
    ref.invalidate(surprisesListProvider);
    ref.invalidate(battleMessagesProvider(widget.surpriseId));

    final battleStatus = newRecord['battle_status'] as String?;
    if (battleStatus != 'resolved') return;
    if (_navigatedToVerdict) return;

    final location = GoRouterState.of(context).matchedLocation;
    if (location != '/shell/battle/${widget.surpriseId}') return;

    _navigatedToVerdict = true;

    ref.read(battleMessagesProvider(widget.surpriseId).future).then((messages) {
      if (!mounted) return;
      final verdict = _verdictMessage(messages);
      if (verdict == null) return;

      final creatorId = newRecord['creator_id'] as String? ?? '';
      final isChaosJudge =
          newRecord['judge_persona'] == AppConstants.personaChaosGremlin;
      final judgeResponse = JudgeResponse(
        score: verdict.verdictScore ?? 0,
        isUnlocked: verdict.verdictUnlocked ?? false,
        commentary: verdict.content,
        hint: null,
        moodEmoji: '⚖️',
        isVerdict: true,
      );
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        if (!_playedUnlockSound) {
          _playedUnlockSound = true;
          _soundService?.playUnlock(heavierHaptic: isChaosJudge);
        }
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        context.push(
          '/shell/reveal/${widget.surpriseId}',
          extra: {'response': judgeResponse, 'creatorId': creatorId},
        );
      });
    });
  }

  @override
  void dispose() {
    _realtime?.dispose();
    _soundService?.dispose();
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
    final surprise =
        await ref.read(surpriseByIdProvider(widget.surpriseId).future);
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

      if (senderType == 'creator') {
        await client.rpc(
          'increment_surprise_creator_defense',
          params: {'p_surprise_id': widget.surpriseId},
        );
        final fetched = await client
            .from('surprises')
            .select()
            .eq('id', widget.surpriseId)
            .single() as Map<String, dynamic>;
        final fetchedSurprise = Surprise.fromJson(fetched);
        final now = DateTime.now().toUtc().toIso8601String();
        await client.from('surprises').update({
          'last_activity_at': now,
          'resistance_score': BattleMath.effectiveResistance(
            difficultyLevel: fetchedSurprise.difficultyLevel,
            creatorDefenseCount: fetchedSurprise.creatorDefenseCount,
            fatigueLevel: fetchedSurprise.fatigueLevel,
          ),
          'fatigue_level': fetchedSurprise.fatigueLevel,
        }).eq('id', widget.surpriseId);
        ref.invalidate(surpriseByIdProvider(widget.surpriseId));
        ref.invalidate(surprisesListProvider);
      }

      ref.invalidate(battleMessagesProvider(widget.surpriseId));
      await Future.delayed(const Duration(milliseconds: 300));

      final messages =
          await ref.read(battleMessagesProvider(widget.surpriseId).future);
      final ai = ref.read(aiJudgeServiceProvider);
      final surpriseContextHint = surprise.unlockMethod.isNotEmpty
          ? 'Surprise type: ${surprise.unlockMethod}'
          : 'romantic surprise';
      final howToImpressHint = _howToImpressHintForSurprise(surprise);
      // Fetch judge memories so the AI remembers past battles
      final couple = ref.read(coupleProvider).value;
      List<String> judgeMemories = [];
      if (couple != null) {
        judgeMemories = await JudgeMemoryService.getMemories(
          client,
          couple.id,
          surprise.judgePersona,
        );
      }

      final judgeResponse = await ai.judgeChat(
        persona: surprise.judgePersona,
        difficultyLevel: surprise.difficultyLevel,
        messages: messages,
        surpriseContextHint: surpriseContextHint,
        howToImpressHint: howToImpressHint,
        judgeMemories: judgeMemories.isNotEmpty ? judgeMemories : null,
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

      final now = DateTime.now().toUtc().toIso8601String();
      final seekerMessageCount =
          messages.where((m) => m.senderType == 'seeker').length + 1;
      final latestSurpriseRow = await client
          .from('surprises')
          .select()
          .eq('id', widget.surpriseId)
          .single() as Map<String, dynamic>;
      final latestSurprise = Surprise.fromJson(latestSurpriseRow);
      final newSeekerScore =
          (latestSurprise.seekerScore + judgeResponse.scoreDelta)
              .clamp(0, AppConstants.seekerScoreMax);
      final effectiveRes = BattleMath.effectiveResistance(
        difficultyLevel: latestSurprise.difficultyLevel,
        creatorDefenseCount: latestSurprise.creatorDefenseCount,
        fatigueLevel: seekerMessageCount,
      );
      final seekerWins =
          (isVerdictNow && judgeResponse.isUnlocked) || effectiveRes == 0;
      final battleService = ref.read(battleServiceProvider);
      if (seekerWins) {
        await battleService.resolveAsSeekerWin(
          widget.surpriseId,
          lastActivityAt: now,
          seekerScore: newSeekerScore,
          resistanceScore: effectiveRes,
          fatigueLevel: seekerMessageCount,
        );
      } else {
        final surpriseUpdate = <String, dynamic>{
          'last_activity_at': now,
          'seeker_score': newSeekerScore,
          'resistance_score': effectiveRes,
          'fatigue_level': seekerMessageCount,
        };
        await client
            .from('surprises')
            .update(surpriseUpdate)
            .eq('id', widget.surpriseId);
      }

      ref.invalidate(battleMessagesProvider(widget.surpriseId));
      ref.invalidate(surpriseByIdProvider(widget.surpriseId));
      ref.invalidate(surprisesListProvider);

      if (seekerWins && mounted) {
        _navigatedToVerdict = true;
        final isChaosJudge =
            surprise.judgePersona == AppConstants.personaChaosGremlin;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          if (!_playedUnlockSound) {
            _playedUnlockSound = true;
            _soundService?.playUnlock(heavierHaptic: isChaosJudge);
          }
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          context.push(
            '/shell/reveal/${widget.surpriseId}',
            extra: {'response': judgeResponse, 'creatorId': surprise.creatorId},
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppTheme.error),
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
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppTheme.error),
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
      final battleService = ref.read(battleServiceProvider);
      await battleService.resolveAsSeekerWin(widget.surpriseId);
      ref.invalidate(surpriseByIdProvider(widget.surpriseId));
      ref.invalidate(surprisesListProvider);
      if (!mounted) return;
      _navigatedToVerdict = true;
      final isChaosJudge =
          surprise.judgePersona == AppConstants.personaChaosGremlin;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        if (!_playedUnlockSound) {
          _playedUnlockSound = true;
          _soundService?.playUnlock(heavierHaptic: isChaosJudge);
        }
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        context.push(
          '/shell/reveal/${widget.surpriseId}',
          extra: {
            'response': JudgeResponse(
              score: 0,
              isUnlocked: true,
              commentary: 'Unlocked with Winks! 🎉',
              hint: null,
              moodEmoji: '😉',
              isVerdict: true,
            ),
            'creatorId': surprise.creatorId,
          },
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppTheme.error),
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
    final userGender = ref.watch(userProfileMetaProvider).gender;

    return surpriseAsync.when(
      data: (surprise) {
        if (surprise == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Battle')),
            body: const Center(child: Text('Surprise not found')),
          );
        }
        if (_showTease) {
          final judgeAsync =
              ref.watch(judgeByPersonaIdProvider(surprise.judgePersona));
          final judge =
              judgeAsync.value ?? Judge.placeholder(surprise.judgePersona);
          return PreBattleTease(
            judge: judge,
            userGender: userGender,
            surpriseId: widget.surpriseId,
            onBegin: () => setState(() => _showTease = false),
          );
        }
        final isCreator = userId == surprise.creatorId;

        // Detect resistance increase (vault reinforced) and fatigue weakening for emotional UX
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final curR = surprise.resistanceScore ?? 0;
          final curF = surprise.fatigueLevel;
          final curE = BattleMath.effectiveResistance(
            difficultyLevel: surprise.difficultyLevel,
            creatorDefenseCount: surprise.creatorDefenseCount,
            fatigueLevel: surprise.fatigueLevel,
          );
          if (_lastResistanceScore == null) {
            setState(() {
              _lastResistanceScore = curR;
              _lastFatigueLevel = curF;
              _lastEffectiveResistance = curE;
            });
            return;
          }
          final resistanceIncreased = curR > _lastResistanceScore!;
          final resistanceDrop = _lastEffectiveResistance! - curE;
          final fatigueWeakened = curF > _lastFatigueLevel! &&
              curE < _lastEffectiveResistance! &&
              resistanceDrop >= AppConstants.fatigueWeakenedMinDrop;
          if (resistanceIncreased || fatigueWeakened) {
            final now = DateTime.now();
            final vaultReinforced = 'The vault was reinforced.';
            final resistanceWeakened = 'Resistance weakened...';
            final debounceSecs =
                AppConstants.battleSystemMessageDebounceSeconds;
            final canAddReinforced = resistanceIncreased &&
                (_lastSystemMessageText != vaultReinforced ||
                    _lastSystemMessageAt == null ||
                    now.difference(_lastSystemMessageAt!).inSeconds >=
                        debounceSecs);
            final canAddWeakened = fatigueWeakened &&
                (_lastSystemMessageText != resistanceWeakened ||
                    _lastSystemMessageAt == null ||
                    now.difference(_lastSystemMessageAt!).inSeconds >=
                        debounceSecs);
            setState(() {
              _lastResistanceScore = curR;
              _lastFatigueLevel = curF;
              _lastEffectiveResistance = curE;
              if (canAddReinforced) {
                _systemMessages.add(vaultReinforced);
                _lastSystemMessageText = vaultReinforced;
                _lastSystemMessageAt = now;
                _pulseResistanceTrigger++;
              }
              if (canAddWeakened) {
                _systemMessages.add(resistanceWeakened);
                _lastSystemMessageText = resistanceWeakened;
                _lastSystemMessageAt = now;
                _flickerResistanceTrigger++;
              }
            });
            if (canAddReinforced)
              _soundService?.playPulse(); // Only when not debounced
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: Text('Judge: ${_personaLabel(surprise.judgePersona)}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: CosmicBackground(
            glowColor: AppTheme.secondaryViolet,
            child: SafeArea(
              child: Column(
                children: [
                  messagesAsync.when(
                    data: (messages) {
                      final verdict = _verdictMessage(messages);
                      if (verdict != null && mounted && !_navigatedToVerdict) {
                        _navigatedToVerdict = true;
                        final isChaosJudge = surprise.judgePersona ==
                            AppConstants.personaChaosGremlin;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          final judgeResponse = JudgeResponse(
                            score: verdict.verdictScore ?? 0,
                            isUnlocked: verdict.verdictUnlocked ?? false,
                            commentary: verdict.content,
                            hint: null,
                            moodEmoji: '⚖️',
                          );
                          Future.delayed(
                            const Duration(milliseconds: 300),
                            () {
                              if (!mounted) return;
                              if (!_playedUnlockSound) {
                                _playedUnlockSound = true;
                                _soundService?.playUnlock(
                                    heavierHaptic: isChaosJudge);
                              }
                            },
                          );
                          Future.delayed(
                            const Duration(milliseconds: 400),
                            () {
                              if (!mounted) return;
                              context.push(
                                '/shell/reveal/${widget.surpriseId}',
                                extra: {
                                  'response': judgeResponse,
                                  'creatorId': surprise.creatorId
                                },
                              );
                            },
                          );
                        });
                      }

                      final status = verdict != null
                          ? 'Verdict in — tap Back to vault'
                          : 'Live — convince the judge!';
                      final resistanceScore = surprise.resistanceScore ??
                          BattleMath.effectiveResistance(
                            difficultyLevel: surprise.difficultyLevel,
                            creatorDefenseCount: surprise.creatorDefenseCount,
                            fatigueLevel: surprise.fatigueLevel,
                          );

                      return Expanded(
                        child: Column(
                          children: [
                            PersuasionMeter(
                              seekerScore: surprise.seekerScore,
                              resistanceScore: resistanceScore,
                              pulseResistanceTrigger: _pulseResistanceTrigger,
                              flickerResistanceTrigger:
                                  _flickerResistanceTrigger,
                              isResolved: verdict != null,
                            ),
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
                                itemCount:
                                    messages.length + _systemMessages.length,
                                itemBuilder: (_, i) {
                                  if (i < messages.length) {
                                    final m = messages[i];
                                    return _ChatBubble(
                                      message: m,
                                      isMe: (m.isFromSeeker && !isCreator) ||
                                          (m.isFromCreator && isCreator),
                                    );
                                  }
                                  return _SystemBubble(
                                    text: _systemMessages[i - messages.length],
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
                                      decoration: InputDecoration(
                                        hintText: 'Type your argument...',
                                        filled: true,
                                        fillColor: Theme.of(context).brightness == Brightness.dark
                                            ? AppTheme.glassFill
                                            : Colors.white.withValues(alpha: 0.60),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                          borderSide: BorderSide(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? AppTheme.glassBorder
                                                : AppTheme.lightGlassBorder,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                          borderSide: BorderSide(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? AppTheme.glassBorder
                                                : AppTheme.lightGlassBorder,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                          borderSide: const BorderSide(
                                            color: AppTheme.primaryPink,
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
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
                                  _SendButton(
                                    isSending: _isSending,
                                    enabled: verdict == null && !_isSending,
                                    onPressed: () {
                                      final type =
                                          isCreator ? 'creator' : 'seeker';
                                      _sendMessage(
                                        type,
                                        _textController.text,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        children: const [
                          SkeletonMessageRow(),
                          SkeletonMessageRow(alignRight: true),
                          SkeletonMessageRow(),
                          SkeletonMessageRow(alignRight: true),
                        ],
                      ),
                    ),
                    error: (_, __) => Expanded(
                      child: ErrorScreen(
                        message: 'Could not load messages. Try again?',
                        onRetry: () => ref.invalidate(
                            battleMessagesProvider(widget.surpriseId)),
                        onBack: () => context.pop(),
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
        appBar: AppBar(
          title: const Text('Battle'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
        ),
        body: CosmicBackground(
          glowColor: AppTheme.secondaryViolet,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: const [
                SkeletonMessageRow(),
                SkeletonMessageRow(alignRight: true),
                SkeletonMessageRow(),
              ],
            ),
          ),
        ),
      ),
      error: (_, __) => ErrorScreen(
        message: 'Something went wrong loading this battle. Try again?',
        onRetry: () {
          ref.invalidate(surpriseByIdProvider(widget.surpriseId));
          ref.invalidate(battleMessagesProvider(widget.surpriseId));
        },
        onBack: () => context.pop(),
      ),
    );
  }
}

class _SystemBubble extends StatelessWidget {
  const _SystemBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: brightness == Brightness.dark
                ? AppTheme.glassFill
                : Colors.white.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(
              color: brightness == Brightness.dark
                  ? AppTheme.glassBorderSubtle
                  : AppTheme.lightGlassBorder,
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: brightness == Brightness.dark
                  ? AppTheme.homeTextSecondary
                  : AppTheme.lightTextSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
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
    final brightness = Theme.of(context).brightness;
    if (message.isFromJudge) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: brightness == Brightness.dark
                  ? AppTheme.glassFill
                  : Colors.white.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.30),
              ),
              boxShadow: AppTheme.elevation1(brightness),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '⚖️ Judge',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message.content,
                  style: GoogleFonts.caveat(
                    fontSize: 18,
                    color: brightness == Brightness.dark
                        ? AppTheme.homeTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (message.isVerdict && message.verdictScore != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusPill),
                      color: AppTheme.accent.withValues(alpha: 0.12),
                    ),
                    child: Text(
                      'Score: ${message.verdictScore}/100 · '
                      '${message.verdictUnlocked == true ? "Unlocked!" : "Denied"}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: brightness == Brightness.dark
                            ? AppTheme.homeTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: isMe
                ? AppTheme.primaryPink.withValues(alpha: 0.20)
                : (brightness == Brightness.dark
                    ? AppTheme.glassFill
                    : Colors.white.withValues(alpha: 0.60)),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: isMe
                  ? AppTheme.primaryPink.withValues(alpha: 0.30)
                  : (brightness == Brightness.dark
                      ? AppTheme.glassBorder
                      : AppTheme.lightGlassBorder),
            ),
          ),
          child: Text(
            message.content,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: brightness == Brightness.dark
                  ? AppTheme.homeTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({
    required this.isSending,
    required this.enabled,
    required this.onPressed,
  });

  final bool isSending;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Send message to judge',
      button: true,
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.enabled) _controller.forward();
        },
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.enabled && !widget.isSending
            ? () {
                if (!kIsWeb) HapticFeedback.lightImpact();
                widget.onPressed();
              }
            : null,
        child: ScaleTransition(
          scale: _scale,
          child: AbsorbPointer(
            child: IconButton.filled(
              onPressed: widget.enabled && !widget.isSending ? () {} : null,
              icon: widget.isSending
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
          ),
        ),
      ),
    );
  }
}
