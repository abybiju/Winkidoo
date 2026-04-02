import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/subscription_provider.dart';

/// Wink+ paywall — shows benefits, pricing, and purchase buttons via RevenueCat.
class WinkPlusScreen extends ConsumerWidget {
  const WinkPlusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveWinkPlus = ref.watch(effectiveWinkPlusProvider);
    final offeringsAsync = ref.watch(rcOfferingsProvider);
    final purchaseState = ref.watch(purchaseNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wink+'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Active badge ──
                if (effectiveWinkPlus) ...[
                  _ActiveBadge(),
                  const SizedBox(height: 24),
                ],

                // ── Header ──
                if (!effectiveWinkPlus) ...[
                  Text(
                    'Unlock more with Wink+',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get the full Winkidoo experience for you and your partner.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Benefits ──
                _BenefitRow(
                  icon: Icons.all_inclusive,
                  title: 'More free attempts',
                  detail:
                      '${AppConstants.winkPlusFreeAttemptsPerDay} judge attempts per day (vs ${AppConstants.freeAttemptsPerDay} free).',
                ),
                _BenefitRow(
                  icon: Icons.face,
                  title: 'All judge personas',
                  detail:
                      'Chaos Gremlin, The Ex, Dr. Love — unlock every persona.',
                ),
                _BenefitRow(
                  icon: Icons.lock_open_rounded,
                  title: 'Full treasure archive',
                  detail:
                      'Relive every surprise with full content and chat replay.',
                ),
                _BenefitRow(
                  icon: Icons.auto_awesome,
                  title: 'Premium badge',
                  detail: 'Show your partner you\'re all in.',
                ),

                const SizedBox(height: 32),

                // ── Pricing / Purchase ──
                if (!effectiveWinkPlus)
                  offeringsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => _ErrorCard(
                      message: 'Could not load pricing. Check your connection.',
                      onRetry: () => ref.invalidate(rcOfferingsProvider),
                    ),
                    data: (offerings) {
                      if (offerings == null ||
                          offerings.current == null ||
                          offerings.current!.availablePackages.isEmpty) {
                        return _NoOfferingsCard();
                      }
                      return _OfferingsSection(
                        packages: offerings.current!.availablePackages,
                        purchaseState: purchaseState,
                        onPurchase: (pkg) {
                          ref
                              .read(purchaseNotifierProvider.notifier)
                              .purchase(pkg)
                              .then((success) {
                            if (success) {
                              ref.invalidate(coupleProvider);
                            }
                          });
                        },
                      );
                    },
                  ),

                // ── Error message ──
                if (purchaseState.status == PurchaseStatus.error &&
                    purchaseState.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    purchaseState.errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.error,
                    ),
                  ),
                ],

                // ── Success message ──
                if (purchaseState.status == PurchaseStatus.success) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Welcome to Wink+! Enjoy all premium benefits.',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Restore purchases ──
                if (!effectiveWinkPlus)
                  TextButton(
                    onPressed: purchaseState.status == PurchaseStatus.restoring
                        ? null
                        : () {
                            ref
                                .read(purchaseNotifierProvider.notifier)
                                .restore()
                                .then((success) {
                              if (success) {
                                ref.invalidate(coupleProvider);
                              }
                            });
                          },
                    child: purchaseState.status == PurchaseStatus.restoring
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Restore purchases',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                  ),

                const SizedBox(height: 16),

                // ── Legal links ──
                Text(
                  'Payment will be charged to your App Store or Google Play account. '
                  'Subscription auto-renews unless cancelled at least 24 hours before the end of the current period.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withValues(alpha: 0.6),
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

// ── Sub-widgets ──

class _ActiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
    );
  }
}

class _OfferingsSection extends StatefulWidget {
  const _OfferingsSection({
    required this.packages,
    required this.purchaseState,
    required this.onPurchase,
  });

  final List<Package> packages;
  final PurchaseState purchaseState;
  final void Function(Package) onPurchase;

  @override
  State<_OfferingsSection> createState() => _OfferingsSectionState();
}

class _OfferingsSectionState extends State<_OfferingsSection> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isPurchasing =
        widget.purchaseState.status == PurchaseStatus.purchasing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Package cards
        ...List.generate(widget.packages.length, (i) {
          final pkg = widget.packages[i];
          final product = pkg.storeProduct;
          final isSelected = i == _selectedIndex;
          final isYearly = pkg.packageType == PackageType.annual;

          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.surface,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Radio indicator
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected ? AppTheme.primary : AppTheme.textSecondary,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isYearly ? 'Yearly' : 'Monthly',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (isYearly) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'SAVE 50%',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.priceString,
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
            ),
          );
        }),

        const SizedBox(height: 8),

        // Purchase button
        FilledButton(
          onPressed: isPurchasing
              ? null
              : () => widget.onPurchase(widget.packages[_selectedIndex]),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isPurchasing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Subscribe to Wink+',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }
}

class _NoOfferingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        AppConstants.revenueCatApiKey.isEmpty
            ? 'In-app purchases are not configured yet. '
                'Add REVENUECAT_API_KEY via --dart-define to enable subscriptions.'
            : 'No subscription plans available right now. Please try again later.',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.error),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
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
