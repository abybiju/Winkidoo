import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/skeleton_card.dart';
import 'package:winkidoo/core/widgets/warm_kit.dart';
import 'package:winkidoo/features/scene_party/scene_party_ui.dart';
import 'package:winkidoo/models/scene_session.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/character_chat_provider.dart';
import 'package:winkidoo/providers/scene_party_provider.dart';
import 'package:winkidoo/providers/supabase_provider.dart';
import 'package:winkidoo/services/scene_director_client.dart';

/// Scene casting room — claim a character, see who's in, start the show.
class SceneCastingScreen extends ConsumerStatefulWidget {
  const SceneCastingScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<SceneCastingScreen> createState() =>
      _SceneCastingScreenState();
}

class _SceneCastingScreenState extends ConsumerState<SceneCastingScreen> {
  bool _starting = false;

  /// Creator kicks off the scene: the Director opens Act 1 server-side, then
  /// we drop into the chat. Fail-soft: any skip/error still lands in chat.
  Future<void> _startScene() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final director =
          SceneDirectorClient(ref.read(supabaseClientProvider));
      final result = await director.start(widget.roomId);
      if (!mounted) return;
      if (result['error'] == 'Claim a character first') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Claim a character before starting the scene!')),
        );
        setState(() => _starting = false);
        return;
      }
      ref.invalidate(sceneSessionProvider(widget.roomId));
      context.go('/shell/chat/${widget.roomId}');
    } catch (e) {
      // The Director engine is fail-soft — enter the chat anyway; a later
      // tick can still open the act.
      if (!mounted) return;
      ref.invalidate(sceneSessionProvider(widget.roomId));
      context.go('/shell/chat/${widget.roomId}');
    }
  }

  String? _claimingCharacterId;

  Future<void> _refresh() async {
    ref.invalidate(sceneSessionProvider(widget.roomId));
    ref.invalidate(sceneCastProvider(widget.roomId));
    ref.invalidate(myRoomsProvider);
    await Future.wait([
      ref.read(sceneSessionProvider(widget.roomId).future),
      ref.read(sceneCastProvider(widget.roomId).future),
    ]);
  }

  Future<void> _claim(SceneCastMember member) async {
    if (_claimingCharacterId != null) return;
    setState(() => _claimingCharacterId = member.characterId);
    try {
      await ref.read(scenePartyServiceProvider).claimCharacter(
            roomId: widget.roomId,
            characterId: member.characterId,
          );
      ref.invalidate(sceneCastProvider(widget.roomId));
    } catch (e) {
      if (mounted) {
        final taken = e.toString().contains('CHARACTER_TAKEN');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(taken
                ? 'Snagged! Someone claimed them first.'
                : "Couldn't claim that role — try again."),
          ),
        );
      }
      ref.invalidate(sceneCastProvider(widget.roomId));
    } finally {
      if (mounted) setState(() => _claimingCharacterId = null);
    }
  }

  void _shareInviteCode(String code) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: code));
    SharePlus.instance.share(
      ShareParams(
        text: 'Join my Scene Party on Winkidoo! Use invite code: $code',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sceneSessionProvider(widget.roomId));

    return Scaffold(
      body: OrbitField(
        cx: 0.5,
        cy: 0.10,
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
                          context.go('/shell/scenes');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Casting Call',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.homeTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: sessionAsync.when(
                  loading: () => ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    children: const [
                      SkeletonCard(),
                      SkeletonCard(),
                      SkeletonCard(),
                    ],
                  ),
                  error: (_, __) => _NotASceneFallback(roomId: widget.roomId),
                  data: (session) {
                    if (session == null) {
                      return _NotASceneFallback(roomId: widget.roomId);
                    }
                    return _buildCasting(context, session);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCasting(BuildContext context, SceneSession session) {
    final castAsync = ref.watch(sceneCastProvider(widget.roomId));
    final packAsync = ref.watch(scenePackByIdProvider(session.packId));
    final room = ref.watch(chatRoomProvider(widget.roomId)).value;
    final myUserId = ref.watch(currentUserProvider)?.id;
    final isCreator = myUserId != null && session.createdBy == myUserId;

    final cast = castAsync.value ?? const <SceneCastMember>[];
    SceneCastMember? mine;
    SceneCastMember? creatorMember;
    for (final member in cast) {
      if (member.userId != null && member.userId == myUserId) mine = member;
      if (member.userId != null && member.userId == session.createdBy) {
        creatorMember = member;
      }
    }
    final creatorName = creatorMember?.displayName ?? 'your host';
    final pack = packAsync.value;
    final inviteCode = room?.inviteCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.primaryOrange,
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pack != null) ...[
                    Row(
                      children: [
                        Text(
                          pack.emoji ?? '🎭',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            pack.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.homeTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    mine == null
                        ? 'Tap a role to claim it — the AI plays the rest.'
                        : 'You can switch roles until the scene starts.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.homeTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Claim grid ──
                  castAsync.when(
                    loading: () => const Column(
                      children: [SkeletonCard(), SkeletonCard()],
                    ),
                    error: (_, __) => Text(
                      'Could not load the cast — pull to refresh.',
                      style: GoogleFonts.inter(
                          color: AppTheme.textMuted, fontSize: 13),
                    ),
                    data: (members) {
                      if (members.isEmpty) {
                        return Text(
                          'No roles yet — pull to refresh.',
                          style: GoogleFonts.inter(
                              color: AppTheme.textMuted, fontSize: 13),
                        );
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.94,
                        ),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final isMine = member.userId != null &&
                              member.userId == myUserId;
                          return _CastSlotCard(
                            member: member,
                            isMine: isMine,
                            isClaiming:
                                _claimingCharacterId == member.characterId,
                            onTap: member.isAi && _claimingCharacterId == null
                                ? () => _claim(member)
                                : null,
                          );
                        },
                      );
                    },
                  ),

                  // ── My secret goal ──
                  if (mine?.secretGoal != null) ...[
                    const SizedBox(height: 16),
                    WarmCard(
                      glow: 0.22,
                      activeBorder: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MonoLabel('🤫 Your secret',
                              color: AppTheme.orangeHi),
                          const SizedBox(height: 6),
                          Text(
                            mine!.secretGoal!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.homeTextPrimary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Work it into the scene — don't say it outright!",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.homeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Invite row ──
                  if (inviteCode != null) ...[
                    const SizedBox(height: 16),
                    WarmCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            PhosphorIconsFill.usersThree,
                            color: AppTheme.primaryOrange,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invite friends to the cast',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.homeTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Room codes are case-sensitive (lowercase
                                // hex) — don't use MonoLabel (it uppercases).
                                Text(
                                  'Code: $inviteCode',
                                  style: AppTheme.mono(
                                    Theme.of(context).brightness,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _shareInviteCode(inviteCode),
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.glassFill,
                                border:
                                    Border.all(color: AppTheme.glassBorder),
                              ),
                              child: const Icon(
                                PhosphorIconsBold.shareNetwork,
                                color: AppTheme.textPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // ── Bottom bar ──
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: isCreator
              ? GlossyButton(
                  full: true,
                  label: _starting ? '🎬 Raising the curtain…' : '🎬 Start the Scene',
                  onTap: _startScene,
                )
              : Column(
                  children: [
                    Text(
                      'Waiting for $creatorName to start…',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.homeTextSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.go('/shell/chat/${widget.roomId}'),
                      child: Text(
                        'Go to chat',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CastSlotCard extends StatelessWidget {
  const _CastSlotCard({
    required this.member,
    required this.isMine,
    required this.isClaiming,
    required this.onTap,
  });

  final SceneCastMember member;
  final bool isMine;
  final bool isClaiming;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = scenePackHexColor(member.characterColorHex);

    return WarmCard(
      padding: const EdgeInsets.all(12),
      radius: 20,
      activeBorder: isMine,
      glow: isMine ? 0.18 : null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.18),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Text(
                  member.characterEmoji ?? '🎭',
                  style: const TextStyle(fontSize: 19),
                ),
              ),
              const Spacer(),
              if (member.isLead)
                const WarmChip(label: 'LEAD', tone: WarmTone.gold),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            member.characterName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.homeTextPrimary,
            ),
          ),
          Expanded(
            child: member.characterTagline == null
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3, bottom: 6),
                      child: Text(
                        member.characterTagline!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppTheme.homeTextSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
          ),
          if (isClaiming)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryOrange,
              ),
            )
          else if (isMine)
            const WarmChip(label: 'You', tone: WarmTone.orange)
          else if (member.isAi)
            const WarmChip(label: 'AI castmate 🤖')
          else
            WarmChip(
              label: member.playerLabel,
              tone: WarmTone.orange,
              icon: GradientAvatar(
                initial: member.playerLabel.isNotEmpty
                    ? member.playerLabel[0].toUpperCase()
                    : '?',
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}

class _NotASceneFallback extends StatelessWidget {
  const _NotASceneFallback({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "This room isn't casting a scene right now.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.go('/shell/chat/$roomId'),
              child: Text(
                'Go to chat',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
