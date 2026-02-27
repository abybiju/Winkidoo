import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/treasure/replay_battle_view.dart';
import 'package:winkidoo/models/battle_message.dart';
import 'package:winkidoo/models/judge.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/providers/battle_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/judges_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/services/encryption_service.dart';

class TreasureDetailScreen extends ConsumerStatefulWidget {
  const TreasureDetailScreen({super.key, required this.surpriseId});

  final String surpriseId;

  @override
  ConsumerState<TreasureDetailScreen> createState() => _TreasureDetailScreenState();
}

class _TreasureDetailScreenState extends ConsumerState<TreasureDetailScreen> {
  String? _decryptedContent;
  String? _photoUrl;
  String? _voiceUrl;
  bool _contentLoading = true;
  String? _contentError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContentIfWinkPlus());
  }

  Future<void> _loadContentIfWinkPlus() async {
    final isWinkPlus = ref.read(effectiveWinkPlusProvider);
    if (!isWinkPlus) {
      setState(() => _contentLoading = false);
      return;
    }
    await _loadContent();
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
          _contentError = 'Content not found';
          _contentLoading = false;
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
            _contentLoading = false;
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
            _contentLoading = false;
          });
        }
        return;
      }
      final contentEncrypted = res['content_encrypted'] as String?;
      if (contentEncrypted == null || contentEncrypted.isEmpty) {
        setState(() {
          _decryptedContent = '';
          _contentLoading = false;
        });
        return;
      }
      final decrypted = await EncryptionService.decrypt(
        contentEncrypted,
        coupleId: couple?.id,
      );
      if (mounted) {
        setState(() {
          _decryptedContent = decrypted;
          _contentLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _contentError = e.toString();
          _contentLoading = false;
        });
      }
    }
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  static String _formatStats({
    required int? persuasion,
    required int? resistance,
    required int? attempts,
    required int? defenses,
  }) {
    final p = persuasion?.toString() ?? '—';
    final r = resistance?.toString() ?? '—';
    final a = attempts?.toString() ?? '—';
    final c = defenses?.toString() ?? '—';
    return 'Persuasion: $p · Resistance: $r · Attempts: $a · Defenses: $c';
  }

  @override
  Widget build(BuildContext context) {
    final surpriseAsync = ref.watch(surpriseByIdProvider(widget.surpriseId));
    final messagesAsync = ref.watch(battleMessagesProvider(widget.surpriseId));
    final isWinkPlus = ref.watch(effectiveWinkPlusProvider);

    return surpriseAsync.when(
      data: (surprise) {
        if (surprise == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Treasure')),
            body: const Center(child: Text('Surprise not found')),
          );
        }
        final judgeAsync = ref.watch(judgeByPersonaIdProvider(surprise.judgePersona));
        final judge = judgeAsync.valueOrNull ?? Judge.placeholder(surprise.judgePersona);
        final messages = messagesAsync.valueOrNull ?? [];
        final seekerAttempts = messages.where((m) => m.isFromSeeker).length;
        final winner = surprise.winner;
        final isSeekerWin = winner == 'seeker';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Treasure'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppTheme.gradientColors(Theme.of(context).brightness),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      judge.name,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSeekerWin
                            ? AppTheme.primary.withValues(alpha: 0.2)
                            : AppTheme.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isSeekerWin ? 'Seeker won' : 'Vault held',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSeekerWin ? AppTheme.primary : AppTheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatDate(surprise.resolvedAt),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatStats(
                          persuasion: surprise.seekerScore,
                          resistance: surprise.resistanceScore,
                          attempts: seekerAttempts,
                          defenses: surprise.creatorDefenseCount,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    if (!isWinkPlus) ...[
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: () => context.push('/shell/wink-plus'),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                        label: const Text('Unlock full memory with Wink+'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                    if (isWinkPlus) ...[
                      const SizedBox(height: 24),
                      if (_contentLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(color: AppTheme.primary),
                          ),
                        )
                      else if (_contentError != null)
                        Text(
                          _contentError!,
                          style: const TextStyle(color: AppTheme.error, fontSize: 14),
                        )
                      else ...[
                        const Text(
                          'Revealed surprise',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_voiceUrl != null)
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
                                child: Center(child: Text('Could not load image')),
                              ),
                            ),
                          )
                        else if (_decryptedContent != null)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.accent, width: 2),
                            ),
                            child: Text(
                              _decryptedContent!,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        const Text(
                          'Battle chat',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (messages.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No messages',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: messages.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) => _DetailChatBubble(
                              message: messages[i],
                            ),
                          ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ReplayBattleView(surpriseId: widget.surpriseId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.replay_rounded, size: 20),
                          label: const Text('Replay Battle'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Treasure')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Treasure')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(), style: const TextStyle(color: AppTheme.error)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(surpriseByIdProvider(widget.surpriseId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailChatBubble extends StatelessWidget {
  const _DetailChatBubble({required this.message});

  final BattleMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isFromJudge) {
      return Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
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
                'Judge',
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
                  'Score: ${message.verdictScore}/100 · '
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
      );
    }
    final isSeeker = message.isFromSeeker;
    return Align(
      alignment: isSeeker ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSeeker ? AppTheme.primary : AppTheme.secondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSeeker ? 'Seeker' : 'Vault',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message.content,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
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
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _toggle,
      icon: Icon(_playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
      label: Text(_playing ? 'Stop' : 'Play voice'),
    );
  }
}
