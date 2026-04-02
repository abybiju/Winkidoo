import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/providers/ai_judge_provider.dart';
import 'package:winkidoo/providers/battle_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/forensics_service.dart';

class ForensicsReportScreen extends ConsumerStatefulWidget {
  const ForensicsReportScreen({super.key, required this.surpriseId});

  final String surpriseId;

  @override
  ConsumerState<ForensicsReportScreen> createState() =>
      _ForensicsReportScreenState();
}

class _ForensicsReportScreenState
    extends ConsumerState<ForensicsReportScreen> {
  ForensicsReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final ai = ref.read(aiJudgeServiceProvider);
      final couple = ref.read(coupleProvider).value;
      if (couple == null) throw Exception('Not linked');

      final messages =
          await ref.read(battleMessagesProvider(widget.surpriseId).future);

      final service = ForensicsService(client, ai);
      final report = await service.generateReport(
        surpriseId: widget.surpriseId,
        coupleId: couple.id,
        messages: messages,
      );

      if (mounted) {
        setState(() {
          _report = report;
          _loading = false;
          if (report == null) _error = 'Could not generate report';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: CosmicBackground(
        showStars: true,
        glowColor: Colors.teal,
        child: SafeArea(
          child: _loading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.teal),
                      const SizedBox(height: 16),
                      Text(
                        'Analyzing your communication DNA...',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.homeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Could not generate report',
                              style: GoogleFonts.inter(
                                  color: AppTheme.homeTextSecondary)),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text('Go back',
                                style: GoogleFonts.inter(
                                    color: AppTheme.primaryOrange)),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: const Icon(
                                    Icons.arrow_back_ios_rounded,
                                    color: Colors.white,
                                    size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Emotional Forensics',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: brightness == Brightness.dark
                                        ? AppTheme.homeTextPrimary
                                        : AppTheme.lightTextPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Superpower badge
                          _SuperpowerBadge(
                              superpower: _report!.superpower),
                          const SizedBox(height: 28),

                          // Communication DNA
                          Text(
                            'Communication DNA',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.homeTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DnaBar(
                              label: 'Logical',
                              value: _report!.communicationDna.logical,
                              color: Colors.blue),
                          _DnaBar(
                              label: 'Emotional',
                              value: _report!.communicationDna.emotional,
                              color: Colors.pink),
                          _DnaBar(
                              label: 'Humorous',
                              value: _report!.communicationDna.humorous,
                              color: Colors.amber),
                          _DnaBar(
                              label: 'Poetic',
                              value: _report!.communicationDna.poetic,
                              color: Colors.purple),
                          const SizedBox(height: 28),

                          // Hidden Signals
                          Text(
                            'Hidden Signals',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.homeTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._report!.hiddenSignals.map((s) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMedium),
                                    color: AppTheme.glassFill,
                                    border: Border.all(
                                        color: AppTheme.glassBorder),
                                  ),
                                  child: Text(
                                    s,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppTheme.homeTextPrimary,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              )),
                          const SizedBox(height: 20),

                          // Growth Edge
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.teal.withValues(alpha: 0.15),
                                  Colors.cyan.withValues(alpha: 0.08),
                                ],
                              ),
                              border: Border.all(
                                  color: Colors.teal.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Growth Edge',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _report!.growthEdge,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppTheme.homeTextPrimary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Back button
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusPill),
                                color: Colors.teal,
                              ),
                              child: Text(
                                'Back to Vault',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _SuperpowerBadge extends StatelessWidget {
  const _SuperpowerBadge({required this.superpower});
  final String superpower;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        gradient: LinearGradient(
          colors: [
            Colors.teal.withValues(alpha: 0.25),
            Colors.cyan.withValues(alpha: 0.15),
          ],
        ),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            'YOUR SUPERPOWER',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.teal.shade300,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            superpower,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DnaBar extends StatelessWidget {
  const _DnaBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.homeTextSecondary,
                ),
              ),
              Text(
                '$value%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: AppTheme.glassFill,
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
