import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/constants/judge_asset_map.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/judge_collectible.dart';
import 'package:winkidoo/providers/collectible_provider.dart';
import 'package:winkidoo/providers/user_profile_provider.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  static const _personas = [
    AppConstants.personaSassyCupid,
    AppConstants.personaPoeticRomantic,
    AppConstants.personaChaosGremlin,
    AppConstants.personaTheEx,
    AppConstants.personaDrLove,
  ];

  static const _personaNames = {
    AppConstants.personaSassyCupid: 'Sassy Cupid',
    AppConstants.personaPoeticRomantic: 'Poetic Romantic',
    AppConstants.personaChaosGremlin: 'Chaos Gremlin',
    AppConstants.personaTheEx: 'The Ex',
    AppConstants.personaDrLove: 'Dr. Love',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectiblesAsync = ref.watch(collectiblesProvider);
    final userGender = ref.watch(userProfileMetaProvider).gender;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.gradientColors(brightness),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded,
                          color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Judge Collection',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: collectiblesAsync.when(
                  data: (collectibles) {
                    final totalCards = collectibles.length;
                    return CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              '$totalCards card${totalCards == 1 ? '' : 's'} collected',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.all(20),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.72,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final persona = _personas[i];
                                final cards = collectibles
                                    .where((c) => c.judgePersona == persona)
                                    .toList();
                                final best = _bestRarity(cards);
                                final assetPath =
                                    JudgeAssetResolver.resolvePersonaAssetPath(
                                  personaId: persona,
                                  userGender: userGender,
                                );
                                return _JudgeCardSlot(
                                  personaName:
                                      _personaNames[persona] ?? persona,
                                  assetPath: assetPath,
                                  count: cards.length,
                                  bestRarity: best,
                                  cards: cards,
                                );
                              },
                              childCount: _personas.length,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryPink),
                  ),
                  error: (_, __) =>
                      const Center(child: Text('Error loading collection')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _bestRarity(List<JudgeCollectible> cards) {
    if (cards.any((c) => c.rarity == 'legendary')) return 'legendary';
    if (cards.any((c) => c.rarity == 'rare')) return 'rare';
    if (cards.isNotEmpty) return 'common';
    return null;
  }
}

class _JudgeCardSlot extends StatelessWidget {
  const _JudgeCardSlot({
    required this.personaName,
    required this.assetPath,
    required this.count,
    required this.bestRarity,
    required this.cards,
  });

  final String personaName;
  final String assetPath;
  final int count;
  final String? bestRarity;
  final List<JudgeCollectible> cards;

  Color get _glowColor {
    switch (bestRarity) {
      case 'legendary':
        return const Color(0xFFF5C76B);
      case 'rare':
        return const Color(0xFFB06EFF);
      default:
        return Colors.white24;
    }
  }

  String get _rarityLabel {
    switch (bestRarity) {
      case 'legendary':
        return '✨ Legendary';
      case 'rare':
        return '💜 Rare';
      case 'common':
        return '⚪ Common';
      default:
        return 'Not earned';
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = bestRarity == null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: locked ? Colors.white12 : _glowColor.withValues(alpha: 0.7),
          width: locked ? 1 : 2,
        ),
        color: locked
            ? Colors.white.withValues(alpha: 0.04)
            : _glowColor.withValues(alpha: 0.08),
        boxShadow: locked
            ? null
            : [
                BoxShadow(
                  color: _glowColor.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ColorFiltered(
                colorFilter: locked
                    ? const ColorFilter.matrix([
                        0.2, 0, 0, 0, 0,
                        0, 0.2, 0, 0, 0,
                        0, 0, 0.2, 0, 0,
                        0, 0, 0, 1, 0,
                      ])
                    : const ColorFilter.mode(
                        Colors.transparent, BlendMode.color),
                child: assetPath.isNotEmpty
                    ? Image.asset(assetPath, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, size: 60, color: Colors.white24))
                    : const Icon(Icons.person, size: 60, color: Colors.white24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              personaName,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: locked
                    ? Colors.white38
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            locked ? 'Win a battle to earn' : _rarityLabel,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: locked ? Colors.white24 : _glowColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!locked) ...[
            const SizedBox(height: 4),
            Text(
              '$count card${count == 1 ? '' : 's'}',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white54,
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
