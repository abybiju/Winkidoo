import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:go_router/go_router.dart';
import 'package:winkidoo/models/judge_response.dart';
import 'package:winkidoo/providers/ai_judge_provider.dart';
import 'package:winkidoo/providers/battle_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/providers/winks_provider.dart';
import 'package:winkidoo/services/encryption_service.dart';
import 'package:winkidoo/features/battle/widgets/battle_share_card.dart';
import 'package:winkidoo/services/share_card_service.dart';
import 'package:winkidoo/services/xp_service.dart';
import 'package:winkidoo/services/judge_memory_service.dart';
import 'package:winkidoo/services/battle_pass_service.dart';
import 'package:winkidoo/services/collectible_service.dart';
import 'package:winkidoo/providers/collectible_provider.dart';
import 'package:winkidoo/providers/xp_provider.dart';

class RevealScreen extends ConsumerStatefulWidget {
  const RevealScreen({
    super.key,
    required this.surpriseId,
    required this.judgeResponse,
    required this.creatorId,
  });

  final String surpriseId;
  final JudgeResponse judgeResponse;
  final String creatorId;

  @override
  ConsumerState<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends ConsumerState<RevealScreen> {
  final _shareCardKey = GlobalKey();
  late ConfettiController _confettiController;
  String? _decryptedContent;
  String? _partnerPiece;
  String? _photoUrl;
  String? _voiceUrl;
  bool _loading = true;
  String? _error;
  bool _buyingHintOrUnlock = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    if (widget.judgeResponse.isUnlocked) {
      _loadContent();
      _awardBattleRewards();
      if (!kIsWeb) {
        HapticFeedback.mediumImpact();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
      });
    } else {
      setState(() => _loading = false);
    }
  }

  /// Awards XP and saves judge memory after a battle win. Non-critical.
  Future<void> _awardBattleRewards() async {
    final client = ref.read(supabaseClientProvider);
    final couple = ref.read(coupleProvider).value;
    if (couple == null) return;

    // Award XP for winning a battle
    await XpService.awardXp(client, couple.id, AppConstants.xpPerBattleWon);
    ref.invalidate(coupleXpProvider);

    // Award Battle Pass points for winning
    await BattlePassService.awardPoints(client, couple.id, 10);

    // Award collectible card
    try {
      final surprise = await ref.read(
        surpriseByIdProvider(widget.surpriseId).future,
      );
      if (surprise != null) {
        await CollectibleService.awardCard(
          client,
          coupleId: couple.id,
          judgePersona: surprise.judgePersona,
          battleId: widget.surpriseId,
          seekerScore: surprise.seekerScore,
        );
        ref.invalidate(collectiblesProvider);
      }
    } catch (_) {}

    // Save judge memory in background (get messages from DB then summarise)
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (apiKey.isNotEmpty) {
      try {
        final messages = await ref.read(
          battleMessagesProvider(widget.surpriseId).future,
        );
        final surprise = await ref.read(
          surpriseByIdProvider(widget.surpriseId).future,
        );
        if (surprise != null) {
          await JudgeMemoryService.saveMemory(
            client,
            apiKey,
            couple.id,
            surprise.judgePersona,
            messages,
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _buyHint() async {
    final surprise = await ref.read(surpriseByIdProvider(widget.surpriseId).future);
    if (surprise == null || !mounted) return;
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
    setState(() => _buyingHintOrUnlock = true);
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
      if (mounted) setState(() => _buyingHintOrUnlock = false);
    }
  }

  Future<void> _buyInstantUnlock() async {
    final surprise = await ref.read(surpriseByIdProvider(widget.surpriseId).future);
    if (surprise == null || !mounted) return;
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
      context.go(
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _loadContent() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final couple = ref.read(coupleProvider).value;
      final res = await client
          .from('surprises')
          .select()
          .eq('id', widget.surpriseId)
          .single();
      if (res == null || res is! Map<String, dynamic>) {
        setState(() {
          _error = 'Content not found';
          _loading = false;
        });
        return;
      }
      final surprise = Surprise.fromJson(res);
      if (surprise.isPhoto && surprise.contentStoragePath != null) {
        final url = await client.storage
            .from(AppConstants.surpriseStorageBucket)
            .createSignedUrl(surprise.contentStoragePath!, 3600);
        if (mounted) {
          setState(() {
            _photoUrl = url;
            _loading = false;
          });
        }
        return;
      }
      if (surprise.isVoice && surprise.contentStoragePath != null) {
        final url = await client.storage
            .from(AppConstants.surpriseStorageBucket)
            .createSignedUrl(surprise.contentStoragePath!, 3600);
        if (mounted) {
          setState(() {
            _voiceUrl = url;
            _loading = false;
          });
        }
        return;
      }
      final contentEncrypted = res['content_encrypted'] as String?;
      if (contentEncrypted == null || contentEncrypted.isEmpty) {
        setState(() {
          _decryptedContent = '';
          _loading = false;
        });
        return;
      }
      final decrypted = await EncryptionService.decrypt(
        contentEncrypted,
        coupleId: couple?.id,
      );

      // Decrypt collab partner piece if present
      final collabEncrypted =
          res['collab_partner_piece_encrypted'] as String?;
      String? partnerPiece;
      if (collabEncrypted != null && collabEncrypted.isNotEmpty) {
        partnerPiece = await EncryptionService.decrypt(
          collabEncrypted,
          coupleId: couple?.id,
        );
      }

      setState(() {
        _decryptedContent = decrypted;
        _partnerPiece = partnerPiece;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  static String _formatBattleStats({
    required int? finalPersuasion,
    required int? finalResistance,
    required int? attempts,
    required int? creatorDefenses,
  }) {
    final p = finalPersuasion?.toString() ?? '—';
    final r = finalResistance?.toString() ?? '—';
    final a = attempts?.toString() ?? '—';
    final c = creatorDefenses?.toString() ?? '—';
    return 'Final persuasion: $p · Resistance: $r · Attempts: $a · Creator defenses: $c';
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.judgeResponse.isUnlocked;
    final surpriseAsync = ref.watch(surpriseByIdProvider(widget.surpriseId));
    final messagesAsync = ref.watch(battleMessagesProvider(widget.surpriseId));

    final surprise = surpriseAsync.value;
    final messages = messagesAsync.value;
    final seekerAttempts = messages != null
        ? messages.where((m) => m.senderType == 'seeker').length
        : null;
    final finalPersuasion = surprise?.seekerScore;
    final finalResistance = surprise?.resistanceScore;
    final creatorDefenses = surprise?.creatorDefenseCount;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppTheme.homeBackgroundGradient(Theme.of(context).brightness),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      unlocked ? '🎉 Unlocked!' : '😔 Denied',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: unlocked ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${widget.judgeResponse.moodEmoji ?? ''} Last turn: ${widget.judgeResponse.score}/100',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.glassFill
                            : Colors.white.withValues(alpha: 0.50),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.glassBorderSubtle
                              : AppTheme.lightGlassBorder,
                        ),
                      ),
                      child: Text(
                        _formatBattleStats(
                          finalPersuasion: finalPersuasion,
                          finalResistance: finalResistance,
                          attempts: seekerAttempts,
                          creatorDefenses: creatorDefenses,
                        ),
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.glassFill
                            : Colors.white.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.glassBorder
                              : AppTheme.lightGlassBorder,
                        ),
                        boxShadow: AppTheme.elevation1(Theme.of(context).brightness),
                      ),
                      child: Text(
                        widget.judgeResponse.commentary,
                        style: GoogleFonts.caveat(
                          fontSize: 20,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (unlocked) ...[
                      const SizedBox(height: 24),
                      if (_loading)
                        const Center(
                          child: CircularProgressIndicator(color: AppTheme.primary),
                        )
                      else if (_error != null)
                        Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.error),
                        )
                      else if (_voiceUrl != null)
                        _VoicePlayer(url: _voiceUrl!)
                      else if (_photoUrl != null)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.accent, width: 2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            _photoUrl!,
                            fit: BoxFit.contain,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                    ? child
                                    : const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(24),
                                          child: CircularProgressIndicator(
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                            errorBuilder: (_, __, ___) => const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Text('Could not load image'),
                              ),
                            ),
                          ),
                        )
                      else if (_decryptedContent != null) ...[
                        if (_partnerPiece != null) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Creator\'s piece',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                            color: AppTheme.accent,
                                            width: 2),
                                      ),
                                      child: Text(
                                        _decryptedContent!,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Partner\'s piece',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                            color: AppTheme.primaryPink,
                                            width: 2),
                                      ),
                                      child: Text(
                                        _partnerPiece!,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppTheme.accent, width: 2),
                            ),
                            child: Text(
                              _decryptedContent!,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                      ],
                    ] else if (widget.judgeResponse.hint != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Hint: ${widget.judgeResponse.hint}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (!unlocked) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Semantics(
                            label:
                                'Get a hint from the judge for ${AppConstants.hintCostWinks} Winks',
                            button: true,
                            child: OutlinedButton.icon(
                              onPressed: _buyingHintOrUnlock
                                  ? null
                                  : _buyHint,
                              icon: Text('${AppConstants.hintCostWinks} 😉'),
                              label: const Text('Get hint'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Semantics(
                            label:
                                'Unlock surprise now for ${AppConstants.instantUnlockCostWinks} Winks',
                            button: true,
                            child: OutlinedButton.icon(
                              onPressed: _buyingHintOrUnlock
                                  ? null
                                  : _buyInstantUnlock,
                              icon: Text(
                                  '${AppConstants.instantUnlockCostWinks} 😉'),
                              label: const Text('Unlock now'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    // Share battle highlight card
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RepaintBoundary(
                                    key: _shareCardKey,
                                    child: BattleShareCard(
                                      judgePersona: surprise?.judgePersona ?? AppConstants.personaSassyCupid,
                                      bestQuote: widget.judgeResponse.commentary,
                                      won: widget.judgeResponse.isUnlocked,
                                      difficulty: surprise?.difficultyLevel ?? 2,
                                      seekerScore: widget.judgeResponse.score,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      ShareCardService.shareCard(_shareCardKey);
                                      Navigator.pop(ctx);
                                    },
                                    icon: const Icon(Icons.share_rounded),
                                    label: const Text('Share'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share Battle Card'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.go('/shell/vault');
                        },
                        child: const Text('Back to vault'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (unlocked)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 30,
                colors: const [
                  AppTheme.primary,
                  AppTheme.accent,
                  AppTheme.secondary,
                ],
                gravity: 0.2,
                shouldLoop: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _VoicePlayer extends StatefulWidget {
  const _VoicePlayer({required this.url});

  final String url;

  @override
  State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.url));
    }
    if (mounted) setState(() => _playing = !_playing);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filled(
            onPressed: _toggle,
            icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _playing ? 'Playing...' : 'Tap to play voice note',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
