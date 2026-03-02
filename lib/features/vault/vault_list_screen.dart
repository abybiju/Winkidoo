import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/error_screen.dart';
import 'package:winkidoo/core/widgets/pill_cta.dart';
import 'package:winkidoo/core/widgets/skeleton_card.dart';
import 'package:winkidoo/core/widgets/wink_card.dart';
import 'package:winkidoo/core/widgets/winkidoo_top_bar.dart';
import 'package:winkidoo/features/battle/battle_chat_screen.dart';
import 'package:winkidoo/features/vault/create_surprise_screen.dart';
import 'package:winkidoo/features/vault/wink_plus_screen.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/battle_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/onboarding_provider.dart';
import 'package:winkidoo/providers/surprise_provider.dart';

class VaultListScreen extends ConsumerStatefulWidget {
  const VaultListScreen({
    super.key,
    this.desktopDetailNavigatorKey,
    this.isDesktopSidebar = false,
    this.showBottomNav = false,
  });

  final GlobalKey<NavigatorState>? desktopDetailNavigatorKey;
  final bool isDesktopSidebar;
  final bool showBottomNav;

  @override
  ConsumerState<VaultListScreen> createState() => _VaultListScreenState();
}

class _VaultListScreenState extends ConsumerState<VaultListScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(surprisesListProvider);
      ref.invalidate(coupleProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime?>(partnerAddedSurpriseAtProvider, (prev, next) {
      if (next != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your partner added a surprise'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(partnerAddedSurpriseAtProvider.notifier).state = null;
      }
    });

    final surprisesAsync = ref.watch(surprisesListProvider);
    final user = ref.watch(currentUserProvider);
    final couple = ref.watch(coupleProvider).value;
    final showWaitingBanner = couple != null && !couple.isLinked;
    final isDesktop = widget.desktopDetailNavigatorKey != null;

    void pushToBattle(String surpriseId) {
      if (isDesktop) {
        widget.desktopDetailNavigatorKey?.currentState?.push(
          MaterialPageRoute<void>(
            builder: (_) => BattleChatScreen(surpriseId: surpriseId),
          ),
        );
      } else {
        context.push('/shell/battle/$surpriseId');
      }
    }

    void pushToCreate() {
      if (isDesktop) {
        widget.desktopDetailNavigatorKey?.currentState?.push(
          MaterialPageRoute<void>(
            builder: (_) => const CreateSurpriseScreen(),
          ),
        );
      } else {
        context.push('/shell/create');
      }
    }

    void pushToWinkPlus() {
      if (isDesktop) {
        widget.desktopDetailNavigatorKey?.currentState?.push(
          MaterialPageRoute<void>(
            builder: (_) => const WinkPlusScreen(),
          ),
        );
      } else {
        context.push('/shell/wink-plus');
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.gradientColors(Theme.of(context).brightness),
          ),
        ),
        child: SafeArea(
          child: surprisesAsync.when(
            data: (surprises) {
              final waiting = surprises
                  .where((s) => s.creatorId != user?.id && !s.isUnlocked)
                  .toList();
              final myVault =
                  surprises.where((s) => s.creatorId == user?.id).toList();
              final isEmpty = waiting.isEmpty && myVault.isEmpty;
              final linkedAt = couple?.linkedAt;
              final streakDays = linkedAt == null
                  ? 0
                  : DateTime.now().difference(linkedAt.toLocal()).inDays + 1;

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        widget.isDesktopSidebar ? 12 : 12,
                        12,
                        widget.isDesktopSidebar ? 12 : 12,
                        10),
                    sliver: SliverToBoxAdapter(
                      child: WinkidooTopBar(
                        showLogo: true,
                        notificationCount: math.min(waiting.length, 9),
                        trailing: InkWell(
                          onTap: pushToWinkPlus,
                          borderRadius: BorderRadius.circular(999),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE86A),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Wink+',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6A4300),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                        horizontal: widget.isDesktopSidebar ? 12 : 14),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'My Vault',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: widget.isDesktopSidebar ? 24 : 44,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        widget.isDesktopSidebar ? 12 : 14,
                        10,
                        widget.isDesktopSidebar ? 12 : 14,
                        0),
                    sliver: SliverToBoxAdapter(
                      child: _LinkedVaultHero(
                        streakDays: streakDays,
                        waitingCount: waiting.length,
                        linked: couple?.isLinked == true,
                      ),
                    ),
                  ),
                  if (showWaitingBanner)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                          widget.isDesktopSidebar ? 12 : 14,
                          10,
                          widget.isDesktopSidebar ? 12 : 14,
                          0),
                      sliver: SliverToBoxAdapter(
                        child: _WaitingForPartnerBanner(
                          inviteCode: couple.inviteCode,
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        widget.isDesktopSidebar ? 12 : 14,
                        12,
                        widget.isDesktopSidebar ? 12 : 14,
                        0),
                    sliver: SliverToBoxAdapter(
                      child: _VaultSearchAndActions(
                        onCreateTap: pushToCreate,
                        onArchiveTap: () =>
                            context.push('/shell/treasure-archive'),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        widget.isDesktopSidebar ? 12 : 14,
                        12,
                        widget.isDesktopSidebar ? 12 : 14,
                        0),
                    sliver: SliverToBoxAdapter(
                      child: _ChestCallout(
                        onEnterVault: () {
                          if (waiting.isNotEmpty) {
                            pushToBattle(waiting.first.id);
                          }
                        },
                      ),
                    ),
                  ),
                  if (isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyVaultState(
                        onCreateTap: pushToCreate,
                        onMarkFirstPromptSeen: () => ref
                            .read(
                                createFirstSurprisePromptSeenProvider.notifier)
                            .setSeen(),
                        promptSeen:
                            ref.watch(createFirstSurprisePromptSeenProvider),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                          widget.isDesktopSidebar ? 12 : 14,
                          14,
                          widget.isDesktopSidebar ? 12 : 14,
                          120),
                      sliver: SliverList.list(
                        children: [
                          if (waiting.isNotEmpty) ...[
                            _SectionTitle(
                              title: 'Waiting for You',
                              actionLabel: 'see all',
                              onActionTap: () {},
                            ),
                            const SizedBox(height: 8),
                            ...waiting.map((s) => _SurpriseCard(
                                  surprise: s,
                                  isForMe: true,
                                  onTap: () => pushToBattle(s.id),
                                )),
                            const SizedBox(height: 8),
                          ],
                          _SectionTitle(
                              title: 'Your Surprises',
                              actionLabel: 'see all',
                              onActionTap: () {}),
                          const SizedBox(height: 8),
                          ...myVault.map((s) => _MyVaultCard(
                              surprise: s, onTapBattle: pushToBattle)),
                        ],
                      ),
                    ),
                ],
              );
            },
            loading: () => ListView(
              padding: EdgeInsets.symmetric(
                  horizontal: widget.isDesktopSidebar ? 12 : 20, vertical: 20),
              children: const [
                SkeletonCard(),
                SizedBox(height: 12),
                SkeletonCard(),
                SizedBox(height: 12),
                SkeletonCard(),
              ],
            ),
            error: (_, __) => ErrorScreen(
              message: 'Could not load surprises. Try again?',
              onRetry: () => ref.invalidate(surprisesListProvider),
            ),
          ),
        ),
      ),
      floatingActionButton: widget.isDesktopSidebar
          ? null
          : FloatingActionButton.extended(
              onPressed: pushToCreate,
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.card_giftcard_rounded),
              label: const Text('Add Surprise'),
            ),
      bottomNavigationBar: widget.showBottomNav
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: PillCta(
                  label: 'Open Wink+',
                  onTap: pushToWinkPlus,
                  icon: Icons.auto_awesome,
                ),
              ),
            )
          : null,
    );
  }
}

class _LinkedVaultHero extends StatelessWidget {
  const _LinkedVaultHero({
    required this.streakDays,
    required this.waitingCount,
    required this.linked,
  });

  final int streakDays;
  final int waitingCount;
  final bool linked;

  @override
  Widget build(BuildContext context) {
    final statusText = linked
        ? 'Vault linked with your partner'
        : 'Vault waiting to be linked';
    final streakText =
        streakDays > 0 ? '$streakDays day streak' : 'Start your streak';

    return WinkCard(
      borderRadius: 34,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFFFC2D7),
                child: Text(
                  'W',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFE85D93),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      waitingCount > 0
                          ? '$waitingCount surprise${waitingCount == 1 ? '' : 's'} waiting for you'
                          : 'No surprises waiting yet',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.73),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PillCta(
            label: streakText,
            onTap: () {},
            icon: Icons.local_fire_department_rounded,
            trailing: true,
          ),
        ],
      ),
    );
  }
}

class _VaultSearchAndActions extends StatelessWidget {
  const _VaultSearchAndActions({
    required this.onCreateTap,
    required this.onArchiveTap,
  });

  final VoidCallback onCreateTap;
  final VoidCallback onArchiveTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE8D7F2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded,
                  size: 28, color: AppTheme.lightTextSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search memories...',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    color: AppTheme.lightTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 56,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE149),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Color(0xFF805500)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PillCta(
                label: 'Add a Surprise',
                onTap: onCreateTap,
                icon: Icons.card_giftcard_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillCta(
                label: 'Uncover Memories',
                onTap: onArchiveTap,
                icon: Icons.auto_awesome,
                trailing: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChestCallout extends StatelessWidget {
  const _ChestCallout({required this.onEnterVault});

  final VoidCallback onEnterVault;

  @override
  Widget build(BuildContext context) {
    return WinkCard(
      borderRadius: 32,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.cardGradientA(Theme.of(context).brightness),
          AppTheme.cardGradientB(Theme.of(context).brightness),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFEBA6), Color(0xFFE8DCFF)],
              ),
            ),
            alignment: Alignment.center,
            child: const Text('🧰', style: TextStyle(fontSize: 92)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded,
                          color: AppTheme.lightTextSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Search memories...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PillCta(
                label: 'Enter Vault',
                onTap: onEnterVault,
                icon: Icons.chevron_right_rounded,
                trailing: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyVaultCard extends ConsumerWidget {
  const _MyVaultCard({
    required this.surprise,
    this.onTapBattle,
  });

  final Surprise surprise;
  final void Function(String surpriseId)? onTapBattle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBattle = ref.watch(hasActiveBattleProvider(surprise.id));

    return hasBattle.when(
      data: (active) => _SurpriseCard(
        surprise: surprise,
        isForMe: false,
        subtitle: active ? 'Battle in progress - tap to join' : null,
        onTap: active ? () => onTapBattle?.call(surprise.id) : () {},
      ),
      loading: () =>
          _SurpriseCard(surprise: surprise, isForMe: false, onTap: () {}),
      error: (_, __) =>
          _SurpriseCard(surprise: surprise, isForMe: false, onTap: () {}),
    );
  }
}

class _EmptyVaultState extends StatelessWidget {
  const _EmptyVaultState({
    required this.onCreateTap,
    required this.onMarkFirstPromptSeen,
    required this.promptSeen,
  });

  final VoidCallback onCreateTap;
  final VoidCallback onMarkFirstPromptSeen;
  final bool promptSeen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: WinkCard(
          borderRadius: 30,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 14),
              Text(
                'Nothing here yet',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Create a surprise for your partner, or wait for them to send one.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.72),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              PillCta(
                label: promptSeen
                    ? 'Create Surprise'
                    : 'Create your first surprise',
                onTap: () {
                  onMarkFirstPromptSeen();
                  onCreateTap();
                },
                icon: Icons.add_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaitingForPartnerBanner extends StatelessWidget {
  const _WaitingForPartnerBanner({required this.inviteCode});

  final String inviteCode;

  @override
  Widget build(BuildContext context) {
    return WinkCard(
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Waiting for your partner',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Share this code with your partner:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    inviteCode,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Code copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(
      {required this.title,
      required this.actionLabel,
      required this.onActionTap});

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onActionTap,
          child: Text(
            actionLabel,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }
}

class _SurpriseCard extends StatelessWidget {
  const _SurpriseCard({
    required this.surprise,
    required this.isForMe,
    required this.onTap,
    this.subtitle,
  });

  final Surprise surprise;
  final bool isForMe;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final personaLabel = _personaLabel(surprise.judgePersona);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WinkCard(
        borderRadius: 24,
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEAB0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isForMe ? '💌' : '🔒',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isForMe ? 'Unlock this surprise' : 'Your sealed surprise',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle ?? 'Judge: $personaLabel',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isForMe || subtitle != null)
              const Icon(Icons.chevron_right_rounded, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  String _personaLabel(String id) {
    switch (id) {
      case AppConstants.personaSassyCupid:
        return 'Sassy Cupid';
      case AppConstants.personaPoeticRomantic:
        return 'Poetic Romantic';
      case AppConstants.personaChaosGremlin:
        return 'Chaos Gremlin';
      case AppConstants.personaTheEx:
        return 'The Ex';
      case AppConstants.personaDrLove:
        return 'Dr. Love';
      default:
        return id;
    }
  }
}
