import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/home/home_screen.dart';
import 'package:winkidoo/models/daily_dare.dart';
import 'package:winkidoo/providers/daily_dare_provider.dart';

/// Modal bottom sheet for submitting a dare response (text only for MVP).
/// Photo and voice can be added later following the create surprise pattern.
class DareResponseSheet extends ConsumerStatefulWidget {
  const DareResponseSheet({super.key, required this.dare});

  final DailyDare dare;

  @override
  ConsumerState<DareResponseSheet> createState() => _DareResponseSheetState();
}

class _DareResponseSheetState extends ConsumerState<DareResponseSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    HapticFeedback.lightImpact();

    await ref.read(dailyDareProvider.notifier).submitResponse(text);

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final personaName =
        HomeScreen.personaDisplayName(widget.dare.judgePersona);

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
              color: AppTheme.primaryOrange.withValues(alpha: 0.2),
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

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.primaryOrangeLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.primaryOrangeLight
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'DAILY DARE',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppTheme.primaryOrangeLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      personaName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textOrangeAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dare text
                Text(
                  widget.dare.dareText,
                  style: GoogleFonts.caveat(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: brightness == Brightness.dark
                        ? AppTheme.textPrimary
                        : AppTheme.lightTextPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),

                // Input
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  maxLength: 500,
                  autofocus: true,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: brightness == Brightness.dark
                        ? AppTheme.textPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type your response...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 15,
                      color: AppTheme.textMuted,
                    ),
                    filled: true,
                    fillColor: brightness == Brightness.dark
                        ? AppTheme.surfaceInput
                        : AppTheme.lightSurfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.glassBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.glassBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.5),
                      ),
                    ),
                    counterStyle: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 16),

                // Submit CTA
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [AppTheme.ctaOrangeA, AppTheme.ctaOrangeB],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.ctaOuterGlow.withValues(alpha: 0.4),
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
                              'Submit Response',
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
