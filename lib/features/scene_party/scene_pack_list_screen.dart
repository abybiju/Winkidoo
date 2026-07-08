import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/skeleton_card.dart';
import 'package:winkidoo/core/widgets/warm_kit.dart';
import 'package:winkidoo/features/scene_party/scene_party_ui.dart';
import 'package:winkidoo/models/scene_pack.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/scene_party_provider.dart';

/// Scene Party pack browser — themed group roleplay rooms.
class ScenePackListScreen extends ConsumerWidget {
  const ScenePackListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(scenePacksProvider);
    final hasWinkPlus = ref.watch(effectiveWinkPlusProvider);

    return Scaffold(
      body: OrbitField(
        cx: 0.5,
        cy: 0.12,
        intensity: 0.85,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/shell/play');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scene Party',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.homeTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Pick a theme, claim a character, and improvise the story '
                  'with friends — the AI directs.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.homeTextSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: packsAsync.when(
                  loading: () => ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    children: const [
                      SkeletonCard(),
                      SkeletonCard(),
                      SkeletonCard(),
                    ],
                  ),
                  error: (_, __) => Center(
                    child: Text(
                      'Could not load scene packs.',
                      style: GoogleFonts.inter(color: AppTheme.textMuted),
                    ),
                  ),
                  data: (packs) {
                    if (packs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'No scenes on the marquee yet — new themes drop soon!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: AppTheme.textMuted),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      itemCount: packs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final pack = packs[index];
                        final locked = pack.isPremium && !hasWinkPlus;
                        return _ScenePackCard(
                          pack: pack,
                          locked: locked,
                          onTap: () {
                            if (locked) {
                              context.push('/shell/wink-plus');
                            } else {
                              context.push('/shell/scenes/${pack.slug}');
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScenePackCard extends StatelessWidget {
  const _ScenePackCard({
    required this.pack,
    required this.locked,
    required this.onTap,
  });

  final ScenePack pack;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = scenePackHexColor(pack.primaryColorHex);
    final secondary = scenePackHexColor(
      pack.secondaryColorHex,
      fallback: AppTheme.orangeDeep,
    );
    final playersLabel = pack.minPlayers == pack.maxPlayers
        ? '${pack.maxPlayers} players'
        : '${pack.minPlayers}–${pack.maxPlayers} players';
    final actsLabel = pack.actCount == 1 ? '1 act' : '${pack.actCount} acts';

    return WarmCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.30),
                  secondary.withValues(alpha: 0.16),
                ],
              ),
              border: Border.all(color: primary.withValues(alpha: 0.35)),
            ),
            child: Text(
              pack.emoji ?? '🎭',
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pack.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.homeTextPrimary,
                        ),
                      ),
                    ),
                    if (locked) ...[
                      const SizedBox(width: 8),
                      const WarmChip(
                        label: 'WINK+',
                        tone: WarmTone.gold,
                        icon: Icon(
                          PhosphorIconsFill.lockSimple,
                          size: 12,
                          color: AppTheme.gold,
                        ),
                      ),
                    ],
                  ],
                ),
                if (pack.tagline != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    pack.tagline!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.homeTextSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    WarmChip(label: playersLabel),
                    WarmChip(label: actsLabel),
                    if (pack.isSeasonal && pack.daysRemaining != null)
                      WarmChip(
                        label: '${pack.daysRemaining}d left',
                        tone: WarmTone.orange,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
