import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/custom_judge.dart';
import 'package:winkidoo/providers/custom_judge_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/models/battle_message.dart';
import 'package:winkidoo/services/ai_judge_service.dart';
import 'package:winkidoo/services/custom_judge_service.dart';

const _geminiApiKey =
    String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

/// Quick audition chat: send one message, see the custom judge respond.
/// On close, prompts with publish/private/share options.
class CustomJudgeAuditionSheet extends ConsumerStatefulWidget {
  const CustomJudgeAuditionSheet({super.key, required this.judge});

  final CustomJudge judge;

  @override
  ConsumerState<CustomJudgeAuditionSheet> createState() =>
      _CustomJudgeAuditionSheetState();
}

class _CustomJudgeAuditionSheetState
    extends ConsumerState<CustomJudgeAuditionSheet> {
  final _controller = TextEditingController();
  String? _judgeResponse;
  bool _loading = false;
  bool _tested = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() => _loading = true);
    HapticFeedback.lightImpact();

    try {
      final judge = AiJudgeService(apiKey: _geminiApiKey);
      final response = await judge.judgeChat(
        persona: 'custom',
        difficultyLevel: widget.judge.difficultyLevel,
        messages: [
          BattleMessage(
            id: 'audition',
            surpriseId: '',
            senderType: 'seeker',
            content: text,
            createdAt: DateTime.now(),
          ),
        ],
        personaPromptOverride: widget.judge.generatedPersonaPrompt,
        howToImpressOverride: widget.judge.generatedHowToImpress,
      );
      setState(() {
        _judgeResponse = response.commentary;
        _tested = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _judgeResponse = 'The judge seems speechless. Try again!';
        _loading = false;
      });
    }
  }

  void _showPostAuditionOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PostAuditionSheet(
        judge: widget.judge,
        onPublish: () async {
          Navigator.pop(ctx);
          final client = ref.read(supabaseClientProvider);
          await CustomJudgeService.publishJudge(client, widget.judge.id);
          ref.invalidate(myCustomJudgesProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Published to marketplace!'),
                backgroundColor: AppTheme.success,
              ),
            );
            Navigator.pop(context);
          }
        },
        onKeepPrivate: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
        onShareLink: () async {
          Navigator.pop(ctx);
          await SharePlus.instance.share(
            ShareParams(
              text:
                  'I created a ${widget.judge.personalityName} judge on Winkidoo! ${widget.judge.moodDisplayName} mood. Try it: winkidoo.app/judge/${widget.judge.id}',
            ),
          );
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? AppTheme.surface2
            : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
              color: AppTheme.primaryOrange.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Text(widget.judge.avatarEmoji,
                      style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Test ${widget.judge.personalityName}',
                            style: GoogleFonts.inter(
                              fontSize: 18, fontWeight: FontWeight.w700,
                              color: AppTheme.homeTextPrimary,
                            )),
                        Text('Send a message to see how they respond',
                            style: GoogleFonts.inter(
                              fontSize: 13, color: AppTheme.textMuted,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Judge response
              if (_judgeResponse != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppTheme.primaryOrange.withValues(alpha: 0.08),
                    border: Border.all(
                      color: AppTheme.glassBorderOrange,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${widget.judge.personalityName} says:',
                          style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppTheme.textOrangeAccent,
                          )),
                      const SizedBox(height: 6),
                      Text(_judgeResponse!,
                          style: GoogleFonts.caveat(
                            fontSize: 19,
                            color: AppTheme.homeTextPrimary,
                            height: 1.4,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Input + send
              if (!_tested) ...[
                Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: brightness == Brightness.dark
                                ? AppTheme.textPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Say something to the judge...',
                            hintStyle: GoogleFonts.inter(
                                fontSize: 15, color: AppTheme.textMuted),
                            filled: true,
                            fillColor: brightness == Brightness.dark
                                ? AppTheme.surfaceInput
                                : AppTheme.lightSurfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: AppTheme.glassBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: AppTheme.glassBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: AppTheme.primaryOrange
                                      .withValues(alpha: 0.5)),
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _loading ? null : _sendMessage,
                        child: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [
                              AppTheme.ctaOrangeA, AppTheme.ctaOrangeB,
                            ]),
                          ),
                          child: _loading
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded,
                                  color: Color(0xFF4A2800), size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Post-test actions
              if (_tested) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                          colors: [AppTheme.ctaOrangeA, AppTheme.ctaOrangeB]),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.ctaOuterGlow.withValues(alpha: 0.4),
                          blurRadius: 12, offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: MaterialButton(
                      onPressed: _showPostAuditionOptions,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      child: Text('Done — What Next?',
                          style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: const Color(0xFF4A2800),
                          )),
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
}

/// Post-audition options: publish, keep private, or share via link.
class _PostAuditionSheet extends StatelessWidget {
  const _PostAuditionSheet({
    required this.judge,
    required this.onPublish,
    required this.onKeepPrivate,
    required this.onShareLink,
  });

  final CustomJudge judge;
  final VoidCallback onPublish;
  final VoidCallback onKeepPrivate;
  final VoidCallback onShareLink;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? AppTheme.surface2
            : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('What would you like to do?',
                  style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppTheme.homeTextPrimary,
                  )),
              const SizedBox(height: 6),
              Text('Your ${judge.personalityName} judge is ready!',
                  style: GoogleFonts.inter(
                    fontSize: 14, color: AppTheme.homeTextSecondary,
                  )),
              const SizedBox(height: 24),

              // Publish to community
              _OptionTile(
                icon: Icons.public_rounded,
                iconColor: AppTheme.success,
                title: 'Publish to Community',
                subtitle: 'Let other couples discover and use this judge',
                onTap: onPublish,
              ),
              const SizedBox(height: 10),

              // Share with a friend
              _OptionTile(
                icon: Icons.share_rounded,
                iconColor: AppTheme.secondaryViolet,
                title: 'Share with a Friend',
                subtitle: 'Send a link so they can try this judge',
                onTap: onShareLink,
              ),
              const SizedBox(height: 10),

              // Keep private
              _OptionTile(
                icon: Icons.lock_rounded,
                iconColor: AppTheme.textMuted,
                title: 'Keep Private',
                subtitle: 'Only you and your partner can use this judge',
                onTap: onKeepPrivate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: brightness == Brightness.dark
              ? AppTheme.glassFill
              : AppTheme.lightGlassFill,
          border: Border.all(
            color: brightness == Brightness.dark
                ? AppTheme.glassBorder
                : AppTheme.lightGlassBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppTheme.homeTextPrimary,
                      )),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textMuted,
                      )),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

