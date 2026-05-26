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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/services/custom_judge_service.dart';

class CustomJudgeMarketplaceScreen extends ConsumerStatefulWidget {
  const CustomJudgeMarketplaceScreen({super.key});

  @override
  ConsumerState<CustomJudgeMarketplaceScreen> createState() =>
      _CustomJudgeMarketplaceScreenState();
}

class _CustomJudgeMarketplaceScreenState
    extends ConsumerState<CustomJudgeMarketplaceScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String? _searchQuery;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: CosmicBackground(
        glowColor: AppTheme.primaryOrange,
        child: SafeArea(
          child: Column(
            children: [
              // Header
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
                    Text('Marketplace',
                        style: GoogleFonts.inter(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          color: AppTheme.homeTextPrimary,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tab bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: brightness == Brightness.dark
                        ? AppTheme.glassFill
                        : AppTheme.lightGlassFill,
                    border: Border.all(
                      color: brightness == Brightness.dark
                          ? AppTheme.glassBorder
                          : AppTheme.lightGlassBorder,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                          colors: [AppTheme.ctaOrangeA, AppTheme.ctaOrangeB]),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: const Color(0xFF4A2800),
                    unselectedLabelColor: brightness == Brightness.dark
                        ? AppTheme.homeTextSecondary
                        : AppTheme.lightTextSecondary,
                    labelStyle: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Judges'),
                      Tab(text: 'Chat Personas'),
                    ],
                  ),
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
                  onSubmitted: (q) => setState(
                      () => _searchQuery = q.trim().isEmpty ? null : q.trim()),
                ),
              ),
              const SizedBox(height: 16),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _MarketplaceTab(
                      useFor: 'battle',
                      searchQuery: _searchQuery,
                      onUse: _useJudge,
                    ),
                    _MarketplaceTab(
                      useFor: 'chat',
                      searchQuery: _searchQuery,
                      onUse: _useJudge,
                    ),
                  ],
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
    ref.invalidate(trendingJudgesProvider('battle'));
    ref.invalidate(trendingJudgesProvider('chat'));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${judge.personalityName} added!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }
}

/// A single tab's content — trending + all/search, filtered by useFor.
class _MarketplaceTab extends ConsumerWidget {
  const _MarketplaceTab({
    required this.useFor,
    required this.searchQuery,
    required this.onUse,
  });

  final String useFor;
  final String? searchQuery;
  final ValueChanged<CustomJudge> onUse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final trendingAsync = ref.watch(trendingJudgesProvider(useFor));
    final filter = (search: searchQuery, useFor: useFor);
    final marketplaceAsync = ref.watch(marketplaceJudgesProvider(filter));
    final emptyLabel =
        useFor == 'chat' ? 'Chat Personas' : 'Judges';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trending
          if (searchQuery == null)
            trendingAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (trending) {
                if (trending.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TRENDING',
                        style: AppTheme.overline(brightness).copyWith(
                          color: AppTheme.homeTextSecondary,
                          letterSpacing: 1.2,
                        )),
                    const SizedBox(height: 10),
                    ...trending.map((j) => _JudgeMarketCard(
                          judge: j, onUse: () => onUse(j))),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),

          // All / search results
          Text(
            searchQuery != null ? 'RESULTS' : 'ALL $emptyLabel'.toUpperCase(),
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
            error: (_, __) => Text('Could not load.',
                style: GoogleFonts.inter(color: AppTheme.textMuted)),
            data: (judges) {
              if (judges.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      searchQuery != null
                          ? 'No results for "$searchQuery".'
                          : 'No $emptyLabel published yet. Be the first!',
                      style: GoogleFonts.inter(color: AppTheme.textMuted),
                    ),
                  ),
                );
              }
              return Column(
                children: judges
                    .map((j) => _JudgeMarketCard(
                          judge: j, onUse: () => onUse(j)))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
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
          _JudgeAvatar(judge: judge, size: 44, emojiSize: 28),
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

class _JudgeAvatar extends StatelessWidget {
  const _JudgeAvatar(
      {required this.judge, this.size = 44, this.emojiSize = 28});

  final CustomJudge judge;
  final double size;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    final rawPath = judge.avatarStoragePath;
    final hasAvatar = rawPath != null && rawPath.isNotEmpty;
    if (!hasAvatar) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
            child: Text(judge.avatarEmoji,
                style: TextStyle(fontSize: emojiSize))),
      );
    }
    final String bucket;
    final String path;
    if (rawPath.contains(':')) {
      bucket = rawPath.split(':').first;
      path = rawPath.split(':').skip(1).join(':');
    } else {
      bucket = 'surprises';
      path = rawPath;
    }
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<String>(
        future: Supabase.instance.client.storage
            .from(bucket)
            .createSignedUrl(path, 3600),
        builder: (ctx, snap) {
          if (!snap.hasData || (snap.data?.isEmpty ?? true)) {
            return Center(
                child: Text(judge.avatarEmoji,
                    style: TextStyle(fontSize: emojiSize)));
          }
          return ClipOval(
            child: Image.network(snap.data!,
                width: size, height: size, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                      child: Text(judge.avatarEmoji,
                          style: TextStyle(fontSize: emojiSize)),
                    )),
          );
        },
      ),
    );
  }
}
