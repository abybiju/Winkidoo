import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/constants/judge_asset_map.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/profile_completion_sheet.dart';
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
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/providers/user_profile_provider.dart';

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
    final userGender = ref.watch(userProfileMetaProvider).gender;
    final isDesktop = widget.desktopDetailNavigatorKey != null;

    Future<void> pushToBattle(String surpriseId) async {
      final ok = await ensureProfileComplete(context, ref);
      if (!context.mounted || !ok) return;
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

    Future<void> pushToCreate() async {
      final ok = await ensureProfileComplete(context, ref);
      if (!context.mounted || !ok) return;
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
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppTheme.homeBackgroundGradient(
                    Theme.of(context).brightness,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.25),
                    radius: 1.1,
                    colors: [
                      AppTheme.homeGlowPink.withValues(alpha: 0.09),
                      AppTheme.homeGlowOrange.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: surprisesAsync.when(
              data: (surprises) {
                final waiting = surprises
                    .where((s) => s.creatorId != user?.id && !s.isUnlocked)
                    .toList();
                final myVault =
                    surprises.where((s) => s.creatorId == user?.id).toList();
                final overlayPair = _selectVaultOverlayPersonas(
                  waiting: waiting,
                  myVault: myVault,
                );
                final heroOverlayAsset = _resolveOverlayAssetPath(
                  personaId: overlayPair.$1,
                  userGender: userGender,
                );
                final chestOverlayAsset = _resolveOverlayAssetPath(
                  personaId: overlayPair.$2,
                  userGender: userGender,
                );
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
                          matchLogoToWordmark: true,
                          logoSize: widget.isDesktopSidebar ? 40 : 42,
                          logoTextSize: widget.isDesktopSidebar ? 22 : 24,
                          notificationCount: math.min(waiting.length, 9),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.isDesktopSidebar) ...[
                                _TopBarCreateButton(onTap: pushToCreate),
                                const SizedBox(width: 8),
                              ],
                              InkWell(
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
                            ],
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
                          overlayAssetPath: heroOverlayAsset,
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
                          overlayAssetPath: chestOverlayAsset,
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
                          isDesktopSidebar: widget.isDesktopSidebar,
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
                                actionLabel: 'View all',
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
                                actionLabel: 'View all',
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
                    horizontal: widget.isDesktopSidebar ? 12 : 20,
                    vertical: 20),
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
        ],
      ),
      floatingActionButton: null,
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

class _LinkedVaultHero extends StatefulWidget {
  const _LinkedVaultHero({
    required this.streakDays,
    required this.waitingCount,
    required this.overlayAssetPath,
  });

  final int streakDays;
  final int waitingCount;
  final String overlayAssetPath;

  @override
  State<_LinkedVaultHero> createState() => _LinkedVaultHeroState();
}

class _LinkedVaultHeroState extends State<_LinkedVaultHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotionPreference();
  }

  void _syncMotionPreference() {
    final mediaDisable =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final platformDisable = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    final shouldReduce = mediaDisable || platformDisable;
    if (shouldReduce == _reducedMotion) return;
    _reducedMotion = shouldReduce;
    if (_reducedMotion) {
      _shimmerController.stop();
      _shimmerController.value = 0;
    } else {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    const title = 'Your Vault';
    final waitingText = widget.waitingCount > 0
        ? '${widget.waitingCount} surprise${widget.waitingCount == 1 ? '' : 's'} waiting for you'
        : 'No surprises waiting yet';
    final streakText = widget.streakDays > 0
        ? '${widget.streakDays} day streak'
        : 'Start your streak';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.vaultHeroGradient(brightness),
        ),
        border: Border.all(color: AppTheme.premiumBorder30(brightness)),
        boxShadow: AppTheme.premiumElevation(brightness),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -14,
            bottom: -8,
            width: 180,
            child: IgnorePointer(
              child: Opacity(
                opacity: brightness == Brightness.dark ? 0.24 : 0.16,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, Colors.black],
                    stops: [0.0, 0.48],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: widget.overlayAssetPath.isEmpty
                      ? const SizedBox.shrink()
                      : Image.asset(
                          widget.overlayAssetPath,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.9),
                    radius: 1.25,
                    colors: AppTheme.vaultHeroGlow(brightness),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppTheme.vaultDramaVignette.withValues(
                        alpha: brightness == Brightness.dark ? 0.74 : 0.40,
                      ),
                      Colors.transparent,
                      AppTheme.vaultHeroCharacterOverlay.withValues(
                        alpha: brightness == Brightness.dark ? 0.20 : 0.12,
                      ),
                    ],
                    stops: const [0.0, 0.58, 1.0],
                  ),
                ),
              ),
            ),
          ),
          if (!_reducedMotion)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, _) {
                    final x = -1.35 + (2.7 * _shimmerController.value);
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        gradient: LinearGradient(
                          begin: Alignment(x, -0.4),
                          end: Alignment(x + 0.56, 0.45),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(
                              alpha:
                                  brightness == Brightness.dark ? 0.06 : 0.10,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    padding: const EdgeInsets.all(9),
                    child: Image.asset(
                      'assets/images/winkidoo new logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFF5C76B),
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          waitingText,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: onSurface.withValues(alpha: 0.76),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.local_fire_department_rounded,
                      label: streakText,
                      expanded: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.inventory_2_rounded,
                      label: widget.waitingCount == 0
                          ? 'No pending surprises'
                          : '${widget.waitingCount} pending',
                      tint: AppTheme.vaultStatusPending,
                      expanded: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBarCreateButton extends StatelessWidget {
  const _TopBarCreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              'Create',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VaultSearchAndActions extends StatelessWidget {
  const _VaultSearchAndActions({
    required this.onArchiveTap,
  });

  final VoidCallback onArchiveTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PillCta(
            label: 'Treasure Archive',
            onTap: onArchiveTap,
            icon: Icons.auto_awesome,
            trailing: true,
            filled: false,
            style: PillCtaStyle.glass,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.tint,
    this.expanded = false,
  });

  final IconData icon;
  final String label;
  final Color? tint;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final chipTint = tint ?? const Color(0xFFCA9E4D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment:
            expanded ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: chipTint),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChestCallout extends StatelessWidget {
  const _ChestCallout({
    required this.onEnterVault,
    required this.overlayAssetPath,
  });

  final VoidCallback onEnterVault;
  final String overlayAssetPath;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return WinkCard(
      borderRadius: 32,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: brightness == Brightness.dark
            ? const [AppTheme.vaultDramaSurfaceA, AppTheme.vaultDramaSurfaceB]
            : [
                AppTheme.cardGradientA(brightness),
                AppTheme.cardGradientB(brightness)
              ],
      ),
      child: Column(
        children: [
          Container(
            height: 172,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: brightness == Brightness.dark
                    ? const [Color(0xFF2A1B45), Color(0xFF1A132D)]
                    : const [Color(0xFFFFEBA6), Color(0xFFE8DCFF)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.45),
                        radius: 1.0,
                        colors: AppTheme.vaultHeroGlow(brightness),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppTheme.vaultDramaVignette.withValues(
                              alpha:
                                  brightness == Brightness.dark ? 0.58 : 0.28,
                            ),
                            Colors.transparent,
                            AppTheme.vaultHeroCharacterOverlay.withValues(
                              alpha:
                                  brightness == Brightness.dark ? 0.16 : 0.08,
                            ),
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -6,
                  top: 6,
                  bottom: 6,
                  width: 150,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: brightness == Brightness.dark ? 0.20 : 0.12,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.transparent, Colors.black],
                          stops: [0.02, 0.56],
                        ).createShader(bounds),
                        blendMode: BlendMode.dstIn,
                        child: overlayAssetPath.isEmpty
                            ? const SizedBox.shrink()
                            : Image.asset(
                                overlayAssetPath,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          color: const Color(0xFFF5C76B),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF5C76B)
                                  .withValues(alpha: 0.42),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 52,
                          color: Color(0xFF694100),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    child: Text(
                      'Open your next surprise when it feels right.',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(
                                alpha: brightness == Brightness.dark
                                    ? 0.84
                                    : 0.74),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: PillCta(
              label: 'Enter Vault',
              onTap: onEnterVault,
              icon: Icons.chevron_right_rounded,
              trailing: true,
              filled: false,
              style: PillCtaStyle.glass,
            ),
          ),
        ],
      ),
    );
  }
}

(String, String) _selectVaultOverlayPersonas({
  required List<Surprise> waiting,
  required List<Surprise> myVault,
}) {
  final orderedCandidates = <String>[
    ...waiting.map((s) => s.judgePersona),
    ...myVault.map((s) => s.judgePersona),
  ];
  String primary = orderedCandidates.firstWhere(
    (p) => p.trim().isNotEmpty,
    orElse: () => AppConstants.personaTheEx,
  );
  String secondary = orderedCandidates.firstWhere(
    (p) => p.trim().isNotEmpty && p != primary,
    orElse: () => AppConstants.personaChaosGremlin,
  );
  if (secondary == primary) {
    secondary = AppConstants.personaChaosGremlin;
  }
  return (primary, secondary);
}

String _resolveOverlayAssetPath({
  required String personaId,
  required String userGender,
}) {
  final personaForOverlay = personaId == AppConstants.personaDrLove
      ? AppConstants.personaTheEx
      : personaId;
  return JudgeAssetResolver.resolvePersonaAssetPath(
    personaId: personaForOverlay,
    userGender: userGender,
  );
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
  const _EmptyVaultState({required this.isDesktopSidebar});

  final bool isDesktopSidebar;

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
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Start by creating your first surprise. Once your partner responds, this vault becomes your shared archive of moments.',
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
              const SizedBox(height: 14),
              Text(
                isDesktopSidebar
                    ? 'Use Create in the top bar to add your first surprise.'
                    : 'Use the + Battle button to add your first surprise.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.72),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onActionTap,
          child: Text(
            actionLabel,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: onSurface.withValues(alpha: 0.7),
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
    final isTimeLocked = surprise.isTimeLocked;
    final accent = isTimeLocked
        ? AppTheme.premiumGold
        : isForMe
            ? AppTheme.vaultCardUrgent
            : AppTheme.vaultCardOwned;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WinkCard(
        borderRadius: 24,
        borderColor: accent.withValues(alpha: 0.38),
        onTap: isTimeLocked ? null : onTap,
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.17),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.44)),
              ),
              child: Text(
                isTimeLocked
                    ? '\u{231B}'
                    : isForMe
                        ? '\u{1F48C}'
                        : '\u{1F512}',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTimeLocked
                        ? 'Time Capsule'
                        : isForMe
                            ? 'Unlock this surprise'
                            : 'Your sealed surprise',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isTimeLocked)
                    Text(
                      _countdownText(surprise.unlockAfter!),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.premiumGold,
                      ),
                    )
                  else
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
            if (isTimeLocked)
              Icon(Icons.hourglass_top_rounded,
                  color: AppTheme.premiumGold.withValues(alpha: 0.6), size: 20)
            else if (isForMe || subtitle != null)
              Icon(Icons.chevron_right_rounded, color: accent),
          ],
        ),
      ),
    );
  }

  String _countdownText(DateTime unlockAt) {
    final diff = unlockAt.difference(DateTime.now());
    if (diff.inDays > 0) {
      return 'Unlocks in ${diff.inDays} day${diff.inDays == 1 ? '' : 's'}';
    } else if (diff.inHours > 0) {
      return 'Unlocks in ${diff.inHours} hour${diff.inHours == 1 ? '' : 's'}';
    } else if (diff.inMinutes > 0) {
      return 'Unlocks in ${diff.inMinutes} min';
    }
    return 'Unlocking soon...';
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
