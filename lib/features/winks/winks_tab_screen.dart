import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/winks_provider.dart';

class WinksTabScreen extends ConsumerWidget {
  const WinksTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final winks = ref.watch(winksBalanceProvider).value;

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: AppTheme.surface.withValues(alpha: 0.8),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.emoji_emotions_rounded, size: 48, color: AppTheme.accent),
                        const SizedBox(height: 12),
                        Text(
                          '${winks?.balance ?? 0}',
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          'Winks',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use Winks for hints, persuasion boosts, and instant unlock.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/shell/wink-plus'),
                  icon: const Icon(Icons.star_rounded, size: 20),
                  label: const Text('Unlock more with Wink+'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
