import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/utils/battle_math.dart';
import 'package:winkidoo/providers/ai_judge_provider.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/battle_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/providers/winks_provider.dart';
import 'package:winkidoo/services/ai_judge_service.dart';
import 'package:uuid/uuid.dart';

class SubmissionScreen extends ConsumerStatefulWidget {
  const SubmissionScreen({super.key, required this.surpriseId});

  final String surpriseId;

  @override
  ConsumerState<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends ConsumerState<SubmissionScreen> {
  final _textController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Write something to convince the judge!'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final attemptCount = await ref.read(todayAttemptsCountProvider.future);
    final winks = await ref.read(winksBalanceProvider.future);
    final freeAttemptsPerDay = ref.read(effectiveFreeAttemptsPerDayProvider);
    final freeAttemptsLeft = freeAttemptsPerDay - attemptCount;
    final canTry = freeAttemptsLeft > 0 || (winks?.balance ?? 0) >= 1;
    if (!canTry) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No attempts left today. Get more Winks!'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final surpriseRes = await client
          .from('surprises')
          .select()
          .eq('id', widget.surpriseId)
          .single();
      final surprise = surpriseRes as Map<String, dynamic>;
      final judgePersona = surprise['judge_persona'] as String;
      final difficulty = surprise['difficulty_level'] as int;
      final creatorId = surprise['creator_id'] as String;

      final ai = ref.read(aiJudgeServiceProvider);
      final judgeResponse = await ai.judge(
        persona: judgePersona,
        difficultyLevel: difficulty,
        submissionText: text,
      );

      final attemptId = const Uuid().v4();
      final userId = ref.read(currentUserProvider)?.id ?? '';
      await client.from('attempts').insert({
        'id': attemptId,
        'surprise_id': widget.surpriseId,
        'user_id': userId,
        'content': text,
        'ai_score': judgeResponse.score,
        'ai_commentary': judgeResponse.commentary,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      final now = DateTime.now().toUtc().toIso8601String();
      final currentSeekerScore = surprise['seeker_score'] as int? ?? 0;
      final newSeekerScore = (currentSeekerScore + judgeResponse.scoreDelta)
          .clamp(0, AppConstants.seekerScoreMax);
      final resistanceScore = BattleMath.effectiveResistance(
        difficultyLevel: difficulty,
        creatorDefenseCount: 0,
        fatigueLevel: 1,
      );
      final battleService = ref.read(battleServiceProvider);
      if (judgeResponse.isUnlocked) {
        await battleService.resolveAsSeekerWin(
          widget.surpriseId,
          lastActivityAt: now,
          seekerScore: newSeekerScore,
          resistanceScore: resistanceScore,
          fatigueLevel: 1,
        );
      } else {
        final surpriseUpdate = <String, dynamic>{
          'seeker_score': newSeekerScore,
          'last_activity_at': now,
          'resistance_score': resistanceScore,
          'fatigue_level': 1,
        };
        await client.from('surprises').update(surpriseUpdate).eq('id', widget.surpriseId);
      }

      ref.invalidate(surpriseByIdProvider(widget.surpriseId));
      ref.invalidate(surprisesListProvider);

      if (freeAttemptsLeft <= 0 && (winks?.balance ?? 0) >= 1) {
        await client.from('winks_balance').update({
          'balance': (winks!.balance - 1),
          'last_updated': DateTime.now().toUtc().toIso8601String(),
        }).eq('user_id', userId);
        await client.from('transactions').insert({
          'user_id': userId,
          'amount': -1,
          'type': 'attempt',
          'description': 'Extra attempt',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      ref.invalidate(todayAttemptsCountProvider);
      ref.invalidate(winksBalanceProvider);

      if (!mounted) return;
      context.push(
        '/shell/deliberation',
        extra: {
          'surpriseId': widget.surpriseId,
          'response': judgeResponse,
          'creatorId': creatorId,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Convince the judge'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.homeBackgroundGradient(Theme.of(context).brightness),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your partner locked a surprise. Persuade the judge to unlock it!',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _textController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Write your argument, love note, or plea...',
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  label: 'Send submission to judge',
                  button: true,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit to judge'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
