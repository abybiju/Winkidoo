import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/features/home/home_screen.dart';
import 'package:winkidoo/providers/campaign_provider.dart';

/// Cinematic chapter intro — judge delivers dialogue with typewriter effect.
class CampaignChapterIntroScreen extends ConsumerStatefulWidget {
  const CampaignChapterIntroScreen({
    super.key,
    required this.campaignId,
    required this.chapterNumber,
  });

  final String campaignId;
  final int chapterNumber;

  @override
  ConsumerState<CampaignChapterIntroScreen> createState() =>
      _CampaignChapterIntroScreenState();
}

class _CampaignChapterIntroScreenState
    extends ConsumerState<CampaignChapterIntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _typewriterController;
  String _displayText = '';
  String _fullText = '';

  @override
  void initState() {
    super.initState();
    _typewriterController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    super.dispose();
  }

  void _startTypewriter(String text) {
    if (_fullText == text) return;
    _fullText = text;
    _typewriterController.duration =
        Duration(milliseconds: (text.length * 30).clamp(2000, 8000));
    _typewriterController.addListener(() {
      final charCount = (_typewriterController.value * _fullText.length).round();
      if (mounted) {
        setState(() {
          _displayText = _fullText.substring(0, charCount);
        });
      }
    });
    _typewriterController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(campaignDetailProvider(widget.campaignId));
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: CosmicBackground(
        showStars: true,
        glowColor: AppTheme.secondaryViolet,
        child: SafeArea(
          child: detailAsync.when(
            loading: () => const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.secondaryViolet),
            ),
            error: (_, __) => Center(
              child: Text('Error loading chapter.',
                  style: GoogleFonts.inter(color: AppTheme.textMuted)),
            ),
            data: (data) {
              if (data == null) {
                return Center(
                  child: Text('Campaign not found.',
                      style: GoogleFonts.inter(color: AppTheme.textMuted)),
                );
              }

              final (campaign, chapters) = data;
              final chapter = chapters.firstWhere(
                (c) => c.chapterNumber == widget.chapterNumber,
                orElse: () => chapters.first,
              );
              final personaName =
                  HomeScreen.personaDisplayName(campaign.judgePersona);
              final dialogue =
                  chapter.introDialogue ?? 'The story continues...';

              // Start typewriter on first build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _startTypewriter(dialogue);
              });

              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                child: Column(
                  children: [
                    const Spacer(flex: 1),

                    // Chapter badge
                    Text(
                      'CHAPTER ${chapter.chapterNumber}',
                      style: AppTheme.overline(brightness).copyWith(
                        color: AppTheme.secondaryViolet,
                        letterSpacing: 2,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      chapter.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.homeTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Judge persona
                    Text(
                      personaName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textOrangeAccent,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Typewriter dialogue
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: brightness == Brightness.dark
                            ? AppTheme.surface2
                            : AppTheme.lightSurfaceElevated,
                        border: Border.all(
                          color: AppTheme.secondaryViolet
                              .withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        _displayText.isEmpty ? ' ' : _displayText,
                        style: GoogleFonts.caveat(
                          fontSize: 22,
                          color: brightness == Brightness.dark
                              ? AppTheme.textPrimary
                              : AppTheme.lightTextPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9B7DFF), Color(0xFF7C5CFC)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.secondaryViolet
                                  .withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: MaterialButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            // Navigate back to campaign detail — quests are created from there
                            context.pop();
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Text(
                            'Begin Chapter',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Skip button
                    TextButton(
                      onPressed: () {
                        if (_typewriterController.isAnimating) {
                          _typewriterController.value = 1.0;
                        } else {
                          context.pop();
                        }
                      },
                      child: Text(
                        _typewriterController.isAnimating
                            ? 'Skip animation'
                            : 'Back',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
