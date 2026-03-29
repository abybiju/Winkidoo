import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/mini_game.dart';
import 'package:winkidoo/providers/mini_game_provider.dart';

/// Bottom sheet for playing the daily mini-game.
class MiniGamePlaySheet extends ConsumerStatefulWidget {
  const MiniGamePlaySheet({super.key, required this.game});

  final MiniGame game;

  @override
  ConsumerState<MiniGamePlaySheet> createState() => _MiniGamePlaySheetState();
}

class _MiniGamePlaySheetState extends ConsumerState<MiniGamePlaySheet> {
  final _controller = TextEditingController();
  String? _selectedOption;
  bool _submitting = false;

  bool get _isWouldYouRather => widget.game.gameType == 'would_you_rather';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final response = _isWouldYouRather
        ? _selectedOption
        : _controller.text.trim();
    if (response == null || response.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    HapticFeedback.lightImpact();

    await ref.read(miniGameProvider.notifier).submitResponse(response);

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? AppTheme.surface2
              : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: AppTheme.secondaryViolet.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Game type badge
                Text(
                  widget.game.gameTypeDisplayName.toUpperCase(),
                  style: AppTheme.overline(brightness).copyWith(
                    color: AppTheme.secondaryViolet,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Game prompt
                Text(
                  widget.game.gamePrompt,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: brightness == Brightness.dark
                        ? AppTheme.textPrimary
                        : AppTheme.lightTextPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),

                // Input area
                if (_isWouldYouRather &&
                    widget.game.gameOptions != null) ...[
                  ...widget.game.gameOptions!.map((option) {
                    final selected = _selectedOption == option;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedOption = option),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: selected
                                ? AppTheme.secondaryViolet
                                    .withValues(alpha: 0.15)
                                : (brightness == Brightness.dark
                                    ? AppTheme.surfaceInput
                                    : AppTheme.lightSurfaceElevated),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.secondaryViolet
                                  : AppTheme.glassBorder,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            option,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                              color: brightness == Brightness.dark
                                  ? AppTheme.textPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ] else ...[
                  TextField(
                    controller: _controller,
                    maxLines: 3,
                    maxLength: 300,
                    autofocus: true,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: brightness == Brightness.dark
                          ? AppTheme.textPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type your answer...',
                      hintStyle:
                          GoogleFonts.inter(fontSize: 15, color: AppTheme.textMuted),
                      filled: true,
                      fillColor: brightness == Brightness.dark
                          ? AppTheme.surfaceInput
                          : AppTheme.lightSurfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.glassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppTheme.secondaryViolet.withValues(alpha: 0.5),
                        ),
                      ),
                      counterStyle: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Submit CTA
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9B7DFF), Color(0xFF7C5CFC)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryViolet.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: MaterialButton(
                      onPressed: _submitting ? null : _submit,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Submit Answer',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
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
