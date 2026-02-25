import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/battle/judge_deliberation_screen.dart';
import 'package:winkidoo/providers/ai_judge_provider.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
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

      if (judgeResponse.isUnlocked) {
        await client.from('surprises').update({
          'is_unlocked': true,
          'unlocked_at': DateTime.now().toUtc().toIso8601String(),
          'battle_status': 'resolved',
          'winner': 'seeker',
        }).eq('id', widget.surpriseId);
      }

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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => JudgeDeliberationScreen(
            surpriseId: widget.surpriseId,
            judgeResponse: judgeResponse,
            creatorId: creatorId,
          ),
        ),
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
          onPressed: () => Navigator.of(context).pop(),
        ),
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
