import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';
import 'package:winkidoo/models/custom_judge.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/custom_judge_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/custom_judge_service.dart';

class CustomJudgeMarketplaceScreen extends ConsumerStatefulWidget {
  const CustomJudgeMarketplaceScreen({super.key});

  @override
  ConsumerState<CustomJudgeMarketplaceScreen> createState() =>
      _CustomJudgeMarketplaceScreenState();
}

class _CustomJudgeMarketplaceScreenState
    extends ConsumerState<CustomJudgeMarketplaceScreen> {
  final _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingJudgesProvider);
    final marketplaceAsync =
        ref.watch(marketplaceJudgesProvider(_searchQuery));
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: CosmicBackground(
        glowColor: AppTheme.primaryOrange,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text('Judge Marketplace',
                        style: GoogleFonts.inter(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          color: AppTheme.homeTextPrimary,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: brightness == Brightness.dark
                        ? AppTheme.textPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search personalities...',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 15, color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.textMuted),
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
                          color: AppTheme.primaryOrange.withValues(alpha: 0.5)),
                    ),
                  ),
                  onSubmitted: (q) =>
                      setState(() => _searchQuery = q.trim().isEmpty ? null : q.trim()),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trending section
                      if (_searchQuery == null) ...[
                        trendingAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (trending) {
                            if (trending.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TRENDING',
                                    style:
                                        AppTheme.overline(brightness).copyWith(
                                      color: AppTheme.homeTextSecondary,
                                      letterSpacing: 1.2,
                                    )),
                                const SizedBox(height: 10),
                                ...trending.map((j) => _JudgeMarketCard(
                                      judge: j,
                                      onUse: () => _useJudge(j),
                                    )),
                                const SizedBox(height: 20),
                              ],
                            );
                          },
                        ),
                      ],

                      // All / search results
                      Text(
                        _searchQuery != null
                            ? 'RESULTS'
                            : 'ALL JUDGES',
                        style: AppTheme.overline(brightness).copyWith(
                          color: AppTheme.homeTextSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      marketplaceAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryOrange),
                        ),
                        error: (_, __) => Text('Could not load judges.',
                            style: GoogleFonts.inter(
                                color: AppTheme.textMuted)),
                        data: (judges) {
                          if (judges.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Center(
                                child: Text(
                                  _searchQuery != null
                                      ? 'No judges found for "$_searchQuery".'
                                      : 'No judges published yet. Be the first!',
                                  style: GoogleFonts.inter(
                                      color: AppTheme.textMuted),
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: judges
                                .map((j) => _JudgeMarketCard(
                                      judge: j,
                                      onUse: () => _useJudge(j),
                                    ))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _useJudge(CustomJudge judge) async {
    HapticFeedback.lightImpact();
    final couple = ref.read(coupleProvider).value;
    if (couple == null) return;

    final client = ref.read(supabaseClientProvider);
    await CustomJudgeService.useJudge(
      client,
      customJudgeId: judge.id,
      coupleId: couple.id,
    );
    ref.invalidate(adoptedJudgesProvider);
    ref.invalidate(trendingJudgesProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${judge.personalityName} added to your judges!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }
}

class _JudgeMarketCard extends StatelessWidget {
  const _JudgeMarketCard({required this.judge, required this.onUse});

  final CustomJudge judge;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
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
          Text(judge.avatarEmoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judge.personalityName,
                    style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppTheme.homeTextPrimary,
                    )),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(judge.moodDisplayName,
                        style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textOrangeAccent,
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(width: 8),
                    Text('${judge.useCount} uses',
                        style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textMuted,
                        )),
                  ],
                ),
                if (judge.previewQuotes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('"${judge.previewQuotes.first}"',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.caveat(
                        fontSize: 15, color: AppTheme.homeTextSecondary,
                      )),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onUse,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                    colors: [AppTheme.ctaOrangeA, AppTheme.ctaOrangeB]),
              ),
              child: Text('Use',
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: const Color(0xFF4A2800),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
