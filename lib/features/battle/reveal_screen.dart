import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/vault/vault_list_screen.dart';
import 'package:winkidoo/models/judge_response.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/encryption_service.dart';

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
  late ConfettiController _confettiController;
  String? _decryptedContent;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    if (widget.judgeResponse.isUnlocked) {
      _loadContent();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadContent() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final couple = await ref.read(coupleProvider.future);
      final res = await client
          .from('surprises')
          .select()
          .eq('id', widget.surpriseId)
          .single();
      final contentEncrypted = res['content_encrypted'] as String?;
      if (contentEncrypted == null) {
        setState(() {
          _error = 'Content not found';
          _loading = false;
        });
        return;
      }
      final decrypted = await EncryptionService.decrypt(
        contentEncrypted,
        coupleId: couple?.id,
      );
      setState(() {
        _decryptedContent = decrypted;
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

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.judgeResponse.isUnlocked;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.backgroundStart,
                  AppTheme.backgroundEnd,
                ],
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
                      '${widget.judgeResponse.moodEmoji ?? ''} Score: ${widget.judgeResponse.score}/100',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
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
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const VaultListScreen(),
                            ),
                            (r) => false,
                          );
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
