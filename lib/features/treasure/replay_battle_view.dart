import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/battle/persuasion_meter.dart';
import 'package:winkidoo/models/battle_message.dart';
import 'package:winkidoo/providers/battle_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';

/// Replays a resolved battle: messages appear in order, meter animates to final at verdict,
/// resistance pulses on creator messages, confetti on unlock. Premium (Wink+) only; gate at call site.
class ReplayBattleView extends ConsumerStatefulWidget {
  const ReplayBattleView({super.key, required this.surpriseId});

  final String surpriseId;

  @override
  ConsumerState<ReplayBattleView> createState() => _ReplayBattleViewState();
}

class _ReplayBattleViewState extends ConsumerState<ReplayBattleView> {
  int _visibleCount = 0;
  int _displaySeekerScore = 0;
  int _displayResistanceScore = 0;
  int _pulseTrigger = 0;
  bool _isResolved = false;
  bool _confettiPlayed = false;
  bool _replayComplete = false;
  bool _replayStarted = false;
  bool _autoStartScheduled = false;
  ConfettiController? _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController?.dispose();
    super.dispose();
  }

  void _advanceReplay(
    List<BattleMessage> messages,
    int finalSeekerScore,
    int finalResistanceScore,
  ) {
    if (_visibleCount >= messages.length) {
      setState(() => _replayComplete = true);
      return;
    }
    final msg = messages[_visibleCount];
    setState(() {
      _visibleCount++;
      if (msg.isFromCreator) {
        _pulseTrigger++;
      }
      if (msg.isVerdict) {
        _displaySeekerScore = finalSeekerScore;
        _displayResistanceScore = finalResistanceScore;
        _isResolved = true;
        if (!_confettiPlayed && msg.verdictUnlocked == true) {
          _confettiPlayed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _confettiController?.play();
          });
        }
      }
    });
  }

  void _startReplay(List<BattleMessage> messages, int finalSeeker, int finalResistance) {
    if (messages.isEmpty) {
      setState(() => _replayComplete = true);
      return;
    }
    if (_replayStarted) return;
    _replayStarted = true;
    const stepDuration = Duration(milliseconds: 1200);
    void scheduleNext() {
      if (_visibleCount >= messages.length) {
        setState(() => _replayComplete = true);
        return;
      }
      Future.delayed(stepDuration, () {
        if (!mounted) return;
        _advanceReplay(messages, finalSeeker, finalResistance);
        if (_visibleCount < messages.length) {
          scheduleNext();
        } else {
          setState(() => _replayComplete = true);
        }
      });
    }
    scheduleNext();
  }

  @override
  Widget build(BuildContext context) {
    final surpriseAsync = ref.watch(surpriseByIdProvider(widget.surpriseId));
    final messagesAsync = ref.watch(battleMessagesProvider(widget.surpriseId));

    return surpriseAsync.when(
      data: (surprise) {
        if (surprise == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Replay Battle'),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(child: Text('Surprise not found')),
          );
        }
        final messages = messagesAsync.valueOrNull ?? [];
        final finalSeeker = surprise.seekerScore;
        final finalResistance = surprise.resistanceScore ?? 0;

        if (!_autoStartScheduled && messages.isNotEmpty) {
          _autoStartScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_replayStarted) {
              _startReplay(messages, finalSeeker, finalResistance);
            }
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Replay Battle'),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.gradientColors(Theme.of(context).brightness),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: PersuasionMeter(
                          seekerScore: _displaySeekerScore,
                          resistanceScore: _displayResistanceScore,
                          maxScore: AppConstants.seekerScoreMax,
                          pulseResistanceTrigger: _pulseTrigger,
                          isResolved: _isResolved,
                          animationDuration: const Duration(milliseconds: 500),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _visibleCount,
                          itemBuilder: (context, i) => _ReplayBubble(message: messages[i]),
                        ),
                      ),
                      if (_replayComplete)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.done_rounded),
                            label: const Text('Done'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_confettiPlayed)
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController!,
                    blastDirectionality: BlastDirectionality.explosive,
                    numberOfParticles: 24,
                    colors: const [
                      AppTheme.primary,
                      AppTheme.accent,
                    ],
                    shouldLoop: false,
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Replay Battle'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Replay Battle'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(), style: const TextStyle(color: AppTheme.error)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  ref.invalidate(surpriseByIdProvider(widget.surpriseId));
                  ref.invalidate(battleMessagesProvider(widget.surpriseId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplayBubble extends StatelessWidget {
  const _ReplayBubble({required this.message});

  final BattleMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isFromJudge) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Center(
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
        ),
      );
    }
    final isSeeker = message.isFromSeeker;
    return Align(
      alignment: isSeeker ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSeeker ? AppTheme.primary : AppTheme.secondary,
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
