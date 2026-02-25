import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/battle/reveal_screen.dart';
import 'package:winkidoo/models/judge_response.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JudgeDeliberationScreen extends ConsumerStatefulWidget {
  const JudgeDeliberationScreen({
    super.key,
    required this.surpriseId,
    required this.judgeResponse,
    required this.creatorId,
  });

  final String surpriseId;
  final JudgeResponse judgeResponse;
  final String creatorId;

  @override
  ConsumerState<JudgeDeliberationScreen> createState() =>
      _JudgeDeliberationScreenState();
}

class _JudgeDeliberationScreenState extends ConsumerState<JudgeDeliberationScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _navigateToReveal();
    });
  }

  void _navigateToReveal() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RevealScreen(
          surpriseId: widget.surpriseId,
          judgeResponse: widget.judgeResponse,
          creatorId: widget.creatorId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emoji = widget.judgeResponse.moodEmoji ?? '🤔';
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.gradientColors(Theme.of(context).brightness),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 24),
                Text(
                  'The judge is deliberating...',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 2,
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
