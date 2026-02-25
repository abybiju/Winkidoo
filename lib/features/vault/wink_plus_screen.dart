import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/couple_provider.dart';

/// Wink+ benefits and upgrade placeholder. IAP / Stripe can be wired later.
class WinkPlusScreen extends ConsumerWidget {
  const WinkPlusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couple = ref.watch(coupleProvider).value;
    final isWinkPlus = couple?.isWinkPlus ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wink+'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isWinkPlus)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: AppTheme.accent, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You have Wink+! Enjoy all benefits.',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Unlock more with Wink+',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                const SizedBox(height: 16),
                _BenefitRow(
                  icon: Icons.all_inclusive,
                  title: 'More free attempts',
                  detail:
                      '${AppConstants.winkPlusFreeAttemptsPerDay} judge attempts per day (vs ${AppConstants.freeAttemptsPerDay} free).',
                ),
                _BenefitRow(
                  icon: Icons.face,
                  title: 'All 5 judge personas',
                  detail:
                      'Chaos Gremlin, The Ex, and Dr. Love — only for Wink+.',
                ),
                _BenefitRow(
                  icon: Icons.auto_awesome,
                  title: 'Premium badge',
                  detail: 'Show your couple you\'re all in.',
                ),
                const SizedBox(height: 32),
                if (!isWinkPlus)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'In-app purchase and subscriptions coming soon. '
                      'You can still enjoy the free tier and spend Winks for extra attempts and hints!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
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

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
