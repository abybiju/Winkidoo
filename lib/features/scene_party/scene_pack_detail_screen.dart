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
import 'package:winkidoo/models/user_friend.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/character_chat_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/scene_party_provider.dart';

/// Scene pack detail — hero, character roster, friend invites, start CTA.
class ScenePackDetailScreen extends ConsumerStatefulWidget {
  const ScenePackDetailScreen({super.key, required this.packSlug});

  final String packSlug;

  @override
  ConsumerState<ScenePackDetailScreen> createState() =>
      _ScenePackDetailScreenState();
}

class _ScenePackDetailScreenState extends ConsumerState<ScenePackDetailScreen> {
  final _selectedFriendIds = <String>{};
  bool _isCreating = false;

  Future<void> _startScene(ScenePack pack) async {
    if (_isCreating) return;
    setState(() => _isCreating = true);
    try {
      final roomId =
          await ref.read(scenePartyServiceProvider).createSceneSession(
                packId: pack.id,
                name: null,
                memberIds: _selectedFriendIds.toList(),
              );
      // The casting screen resolves the room via chatRoomProvider, which reads
      // from the cached rooms list — refresh it so the new room is found.
      ref.invalidate(myRoomsProvider);
      if (mounted) context.go('/shell/scenes/cast/$roomId');
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('PREMIUM_REQUIRED')) {
        context.push('/shell/wink-plus');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Couldn't set the stage — give it another go in a sec."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final packAsync = ref.watch(scenePackBySlugProvider(widget.packSlug));

    return Scaffold(
      body: OrbitField(
        cx: 0.5,
        cy: 0.10,
        intensity: 0.85,
        child: SafeArea(
          child: packAsync.when(
            loading: () => ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              children: const [SkeletonCard(), SkeletonCard(), SkeletonCard()],
            ),
            error: (_, __) => Center(
              child: Text(
                'Could not load this scene pack.',
                style: GoogleFonts.inter(color: AppTheme.textMuted),
              ),
            ),
            data: (pack) {
              if (pack == null) {
                return Center(
                  child: Text(
                    'Scene pack not found.',
                    style: GoogleFonts.inter(color: AppTheme.textMuted),
                  ),
                );
              }
              return _buildDetail(context, pack);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, ScenePack pack) {
    final hasWinkPlus = ref.watch(effectiveWinkPlusProvider);
    final locked = pack.isPremium && !hasWinkPlus;
    final charactersAsync = ref.watch(scenePackCharactersProvider(pack.id));
    final friendsAsync = ref.watch(friendsListProvider);
    final user = ref.watch(currentUserProvider);
    final primary = scenePackHexColor(pack.primaryColorHex);
    final secondary = scenePackHexColor(
      pack.secondaryColorHex,
      fallback: AppTheme.orangeDeep,
    );
    final playersLabel = pack.minPlayers == pack.maxPlayers
        ? '${pack.maxPlayers} players'
        : '${pack.minPlayers}–${pack.maxPlayers} players';
    final actsLabel = pack.actCount == 1 ? '1 act' : '${pack.actCount} acts';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
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
                ),
                const SizedBox(height: 8),

                // ── Pack hero ──
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primary.withValues(alpha: 0.34),
                              secondary.withValues(alpha: 0.18),
                            ],
                          ),
                          border:
                              Border.all(color: primary.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.30),
                              blurRadius: 34,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Text(
                          pack.emoji ?? '🎭',
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        pack.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.homeTextPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (pack.tagline != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          pack.tagline!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppTheme.homeTextSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          WarmChip(label: playersLabel),
                          WarmChip(label: actsLabel),
                          if (pack.isSeasonal && pack.daysRemaining != null)
                            WarmChip(
                              label: '${pack.daysRemaining}d left',
                              tone: WarmTone.orange,
                            ),
                          if (locked)
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                if (pack.description != null) ...[
                  Text(
                    pack.description!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.homeTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],

                // ── Character roster ──
                const MonoLabel('The cast'),
                const SizedBox(height: 10),
                charactersAsync.when(
                  loading: () => const Column(
                    children: [SkeletonCard(), SkeletonCard()],
                  ),
                  error: (_, __) => Text(
                    'Could not load the cast.',
                    style: GoogleFonts.inter(
                        color: AppTheme.textMuted, fontSize: 13),
                  ),
                  data: (characters) {
                    if (characters.isEmpty) {
                      return Text(
                        'Casting in progress — check back soon.',
                        style: GoogleFonts.inter(
                            color: AppTheme.textMuted, fontSize: 13),
                      );
                    }
                    return Column(
                      children: [
                        for (final character in characters) ...[
                          _CharacterCard(character: character),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),

                // ── Friend invites ──
                const MonoLabel('Invite friends'),
                const SizedBox(height: 4),
                Text(
                  'Optional — going solo means the AI plays every other part.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.homeTextSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                friendsAsync.when(
                  loading: () => const SkeletonCard(),
                  error: (_, __) => Text(
                    'Failed to load friends.',
                    style: GoogleFonts.inter(
                        color: AppTheme.textMuted, fontSize: 13),
                  ),
                  data: (friends) {
                    final accepted =
                        friends.where((f) => f.isAccepted).toList();
                    if (accepted.isEmpty) {
                      return WarmCard(
                        child: Text(
                          'No friends added yet — no worries! Start solo and '
                          'share the invite code from the casting room.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.homeTextSecondary,
                            height: 1.4,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final friend in accepted)
                          _FriendPickTile(
                            friend: friend,
                            friendUserId: friend.friendId(user?.id ?? ''),
                            isSelected: _selectedFriendIds
                                .contains(friend.friendId(user?.id ?? '')),
                            onToggle: () {
                              final id = friend.friendId(user?.id ?? '');
                              setState(() {
                                if (_selectedFriendIds.contains(id)) {
                                  _selectedFriendIds.remove(id);
                                } else {
                                  _selectedFriendIds.add(id);
                                }
                              });
                            },
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // ── Start CTA ──
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _selectedFriendIds.isEmpty
                    ? 'Solo run — AI castmates fill every other role.'
                    : _selectedFriendIds.length == 1
                        ? '1 friend invited — the AI plays unclaimed roles.'
                        : '${_selectedFriendIds.length} friends invited — the '
                            'AI plays unclaimed roles.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.homeTextSecondary,
                ),
              ),
              const SizedBox(height: 10),
              GlossyButton(
                full: true,
                label: locked
                    ? 'Unlock with Wink+'
                    : _isCreating
                        ? 'Setting the stage…'
                        : 'Start a Scene',
                onTap: _isCreating
                    ? null
                    : locked
                        ? () => context.push('/shell/wink-plus')
                        : () => _startScene(pack),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.character});

  final SceneCharacter character;

  @override
  Widget build(BuildContext context) {
    final accent = scenePackHexColor(character.colorHex);
    return WarmCard(
      padding: const EdgeInsets.all(12),
      radius: 20,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.18),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Text(
              character.emoji ?? '🎭',
              style: const TextStyle(fontSize: 21),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        character.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.homeTextPrimary,
                        ),
                      ),
                    ),
                    if (character.isLead) ...[
                      const SizedBox(width: 8),
                      const WarmChip(label: 'LEAD', tone: WarmTone.gold),
                    ],
                  ],
                ),
                if (character.tagline != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    character.tagline!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.homeTextSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendPickTile extends StatelessWidget {
  const _FriendPickTile({
    required this.friend,
    required this.friendUserId,
    required this.isSelected,
    required this.onToggle,
  });

  final UserFriend friend;
  final String friendUserId;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final name = friend.friendDisplayName ?? friend.friendEmail ?? 'Friend';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: WarmCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        radius: 20,
        activeBorder: isSelected,
        onTap: onToggle,
        child: Row(
          children: [
            GradientAvatar(initial: initial, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.homeTextPrimary,
                ),
              ),
            ),
            AnimatedContainer(
              duration: AppTheme.microDuration,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? AppTheme.primaryOrange : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryOrange
                      : AppTheme.warmLineHi,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
