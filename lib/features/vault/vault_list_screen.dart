import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/error_screen.dart';
import 'package:winkidoo/core/widgets/skeleton_card.dart';
import 'package:winkidoo/features/vault/create_surprise_screen.dart';
import 'package:winkidoo/features/vault/wink_plus_screen.dart';
import 'package:winkidoo/features/battle/battle_chat_screen.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/battle_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/models/surprise.dart';
import 'package:winkidoo/providers/surprise_provider.dart';
import 'package:winkidoo/providers/onboarding_provider.dart';
import 'package:winkidoo/providers/theme_provider.dart';
import 'package:winkidoo/providers/winks_provider.dart';

class VaultListScreen extends ConsumerStatefulWidget {
  const VaultListScreen({
    super.key,
    this.desktopDetailNavigatorKey,
    this.isDesktopSidebar = false,
    this.showBottomNav = false,
  });

  /// When set (desktop two-panel), push battle/create to this navigator instead of context.
  final GlobalKey<NavigatorState>? desktopDetailNavigatorKey;
  final bool isDesktopSidebar;
  /// When false (e.g. inside 4-tab shell), only the shell's bottom nav is shown; this avoids duplicate bar.
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
    final winksAsync = ref.watch(winksBalanceProvider);
    final user = ref.watch(currentUserProvider);
    final coupleAsync = ref.watch(coupleProvider);
    final couple = coupleAsync.value;
    final effectiveWinkPlus = ref.watch(effectiveWinkPlusProvider);
    final showWaitingBanner =
        couple != null && !couple.isLinked;
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.gradientColors(Theme.of(context).brightness),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.all(widget.isDesktopSidebar ? 12 : 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        AppConstants.appName,
                        style: GoogleFonts.poppins(
                          fontSize: widget.isDesktopSidebar ? 18 : 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            final notifier = ref.read(themeModeProvider.notifier);
                            final current = ref.read(themeModeProvider);
                            if (current == ThemeMode.system) {
                              notifier.setThemeMode(ThemeMode.light);
                            } else if (current == ThemeMode.light) {
                              notifier.setThemeMode(ThemeMode.dark);
                            } else {
                              notifier.setThemeMode(ThemeMode.system);
                            }
                          },
                          icon: Icon(
                            ref.watch(themeModeProvider) == ThemeMode.light
                                ? Icons.light_mode
                                : ref.watch(themeModeProvider) == ThemeMode.dark
                                    ? Icons.dark_mode
                                    : Icons.brightness_auto,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: 'Toggle theme',
                        ),
                        if (widget.isDesktopSidebar)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: IconButton(
                              onPressed: pushToCreate,
                              icon: const Icon(Icons.add_circle_outline),
                              color: AppTheme.primary,
                              tooltip: 'Create surprise',
                            ),
                          ),
                        GestureDetector(
                          onTap: pushToWinkPlus,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: effectiveWinkPlus
                                  ? AppTheme.accent.withValues(alpha: 0.3)
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              effectiveWinkPlus ? 'Wink+ ✓' : 'Wink+',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        winksAsync.when(
                          data: (w) => Text(
                            '${w?.balance ?? 0} 😉',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              color: AppTheme.accent,
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showWaitingBanner) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _WaitingForPartnerBanner(inviteCode: couple.inviteCode),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: surprisesAsync.when(
                  data: (surprises) {
                    final forMe = surprises
                        .where((s) =>
                            s.creatorId != user?.id &&
                            !s.isUnlocked)
                        .toList();
                    final myVault = surprises
                        .where((s) => s.creatorId == user?.id)
                        .toList();
                    final isEmpty = forMe.isEmpty && myVault.isEmpty;

                    if (isEmpty) {
                      return _EmptyVaultState(
                        onCreateTap: pushToCreate,
                        onMarkFirstPromptSeen: () =>
                            ref.read(createFirstSurprisePromptSeenProvider.notifier).setSeen(),
                        promptSeen: ref.watch(createFirstSurprisePromptSeenProvider),
                      );
                    }

                    return ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isDesktopSidebar ? 12 : 20,
                      ),
                      children: [
                        if (forMe.isNotEmpty) ...[
                          Text(
                            'Waiting for You',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...forMe.map((s) => _SurpriseCard(
                                surprise: s,
                                isForMe: true,
                                onTap: () => pushToBattle(s.id),
                              )),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          'Your Surprises',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...myVault.map((s) => _MyVaultCard(
                              surprise: s,
                              onTapBattle: pushToBattle,
                            )),
                        const SizedBox(height: 80),
                      ],
                    );
                  },
                  loading: () => ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isDesktopSidebar ? 12 : 20,
                    ),
                    children: const [
                      SkeletonCard(),
                      SkeletonCard(),
                      SkeletonCard(),
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
        ),
      ),
      floatingActionButton: widget.isDesktopSidebar
          ? null
          : FloatingActionButton.extended(
              onPressed: pushToCreate,
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add),
              label: const Text('Hide a surprise'),
            ),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavigationBar(
              currentIndex: 0,
              onTap: (i) {
                if (i == 1) {
                  context.push('/shell/wink-plus');
                }
              },
              backgroundColor: AppTheme.surface,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.textSecondary,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.inbox_rounded),
                  label: 'Vault',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.workspace_premium),
                  label: 'Wink+',
                ),
              ],
            )
          : null,
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
        subtitle: active ? 'Battle in progress — tap to join' : null,
        onTap: active
            ? () => onTapBattle?.call(surprise.id)
            : () {},
      ),
      loading: () => _SurpriseCard(
        surprise: surprise,
        isForMe: false,
        onTap: () {},
      ),
      error: (_, __) => _SurpriseCard(
        surprise: surprise,
        isForMe: false,
        onTap: () {},
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Nothing here yet',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Create a surprise for your partner, or wait for them to send one.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                onMarkFirstPromptSeen();
                onCreateTap();
              },
              icon: const Icon(Icons.add),
              label: Text(promptSeen ? 'Create surprise' : 'Create your first surprise'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Waiting for your partner',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share this code with your partner:',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      inviteCode,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                  icon: const Icon(Icons.copy),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isForMe ? '🎁' : '🔒',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isForMe ? 'Unlock this!' : 'Your surprise',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle ?? 'Judge: $personaLabel',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: subtitle != null
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isForMe || subtitle != null)
                const Icon(Icons.chevron_right, color: AppTheme.primary),
            ],
          ),
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
