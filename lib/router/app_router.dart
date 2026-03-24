import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/auth/couple_link_screen.dart';
import 'package:winkidoo/features/auth/login_screen.dart';
import 'package:winkidoo/features/couple/vault_sealed_screen.dart';
import 'package:winkidoo/features/auth/welcome_auth_screen.dart';
import 'package:winkidoo/features/battle/battle_chat_screen.dart';
import 'package:winkidoo/features/battle/judge_deliberation_screen.dart';
import 'package:winkidoo/features/battle/reveal_screen.dart';
import 'package:winkidoo/features/home/home_screen.dart';
import 'package:winkidoo/features/onboarding/onboarding_screen.dart';
import 'package:winkidoo/features/profile/profile_screen.dart';
import 'package:winkidoo/features/treasure/treasure_archive_screen.dart';
import 'package:winkidoo/features/treasure/treasure_detail_screen.dart';
import 'package:winkidoo/features/vault/create_surprise_screen.dart';
import 'package:winkidoo/features/vault/realtime_surprises_subscription.dart';
import 'package:winkidoo/features/vault/wink_plus_screen.dart';
import 'package:winkidoo/features/winks/winks_tab_screen.dart';
import 'package:winkidoo/core/layout/responsive_vault_shell.dart';
import 'package:winkidoo/core/widgets/wink_bottom_nav.dart';
import 'package:winkidoo/features/quest/quest_create_screen.dart';
import 'package:winkidoo/features/quest/quest_progress_screen.dart';
import 'package:winkidoo/features/quest/quest_complete_screen.dart';
import 'package:winkidoo/features/battlepass/battle_pass_screen.dart';
import 'package:winkidoo/features/referral/referral_screen.dart';
import 'package:winkidoo/features/vault/add_collab_piece_screen.dart';
import 'package:winkidoo/features/collection/collection_screen.dart';
import 'package:winkidoo/features/leaderboard/leaderboard_screen.dart';
import 'package:winkidoo/features/timeline/timeline_screen.dart';
import 'package:winkidoo/models/judge_response.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/onboarding_provider.dart';

const Duration _kAndroidExitBackWindow = Duration(seconds: 2);
const String _kAndroidExitBackPrompt = 'Press back again to exit';

/// Notifier for go_router redirect: updated when auth/couple/onboarding changes.
class RouterRefreshNotifier extends ChangeNotifier {
  bool _authLoading = true;
  bool? _authenticated;
  bool _onboardingComplete = false;
  bool? _hasCouple;
  bool? _isCoupleLinked;

  bool get isAuthLoading => _authLoading;
  bool? get isAuthenticated => _authenticated;
  bool get onboardingComplete => _onboardingComplete;
  bool? get hasCouple => _hasCouple;
  bool? get isCoupleLinked => _isCoupleLinked;

  void update(
    bool authLoading,
    bool? authenticated,
    bool onboardingComplete,
    bool? hasCouple, {
    bool? isCoupleLinked,
  }) {
    if (_authLoading != authLoading ||
        _authenticated != authenticated ||
        _onboardingComplete != onboardingComplete ||
        _hasCouple != hasCouple ||
        _isCoupleLinked != isCoupleLinked) {
      _authLoading = authLoading;
      _authenticated = authenticated;
      _onboardingComplete = onboardingComplete;
      _hasCouple = hasCouple;
      _isCoupleLinked = isCoupleLinked;
      notifyListeners();
    }
  }
}

final routerRefreshNotifier = RouterRefreshNotifier();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: routerRefreshNotifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (routerRefreshNotifier.isAuthLoading) return null;
      if (routerRefreshNotifier.isAuthenticated != true) {
        if (loc != '/' && loc != '/login') return '/';
        return null;
      }
      if (!routerRefreshNotifier.onboardingComplete) {
        if (loc != '/onboarding') return '/onboarding';
        return null;
      }
      if (routerRefreshNotifier.hasCouple == false) {
        if (loc != '/couple-link') return '/couple-link';
        return null;
      }
      if (routerRefreshNotifier.hasCouple == true) {
        final isLinked = routerRefreshNotifier.isCoupleLinked == true;
        if (loc == '/' ||
            loc == '/login' ||
            loc == '/onboarding' ||
            loc == '/couple-link') {
          return isLinked ? '/shell/vault' : '/vault-sealed';
        }
        if (loc == '/vault-sealed' && isLinked) return '/shell/vault';
        if (loc == '/shell') return '/shell/vault';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const WelcomeAuthScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, state) {
          final extra = state.extra;
          final email = (extra is Map ? (extra['email'] as String?) : null);
          final mode = (extra is Map ? (extra['mode'] as String?) : null);
          final initialSignUp = mode == 'signUp';
          return LoginScreen(
            initialEmail: email,
            initialSignUp: mode != null ? initialSignUp : null,
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, _) => Consumer(
          builder: (context, ref, _) => OnboardingScreen(
            onComplete: () {
              ref.read(onboardingCompleteProvider.notifier).setComplete();
              context.go('/shell/vault');
            },
          ),
        ),
      ),
      GoRoute(
        path: '/couple-link',
        builder: (_, __) => const CoupleLinkScreen(),
      ),
      GoRoute(
        path: '/vault-sealed',
        builder: (context, _) => Consumer(
          builder: (context, ref, _) {
            final coupleAsync = ref.watch(coupleProvider);
            return coupleAsync.when(
              data: (couple) {
                if (couple == null || couple.isLinked) {
                  return Scaffold(
                    body: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.bgTop,
                            AppTheme.bgBottom,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ),
                  );
                }
                return VaultSealedScreen(inviteCode: couple.inviteCode);
              },
              loading: () => Scaffold(
                body: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.bgTop,
                        AppTheme.bgBottom,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ),
              ),
              error: (_, __) => Scaffold(
                body: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.bgTop,
                        AppTheme.bgBottom,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final loc = state.matchedLocation;
          int index = 0;
          if (loc.startsWith('/shell/vault')) {
            index = 1;
          } else if (loc.startsWith('/shell/winks')) {
            index = 2;
          } else if (loc.startsWith('/shell/profile')) {
            index = 3;
          }
          return _ShellScaffold(
            matchedLocation: loc,
            currentIndex: index,
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shell/home',
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shell/vault',
                builder: (_, __) => const RealtimeSurprisesSubscription(
                  child: ResponsiveVaultShell(isInsideShell: true),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shell/winks',
                builder: (_, __) => const WinksTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shell/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/shell/create',
        builder: (_, __) => const CreateSurpriseScreen(),
      ),
      GoRoute(
        path: '/shell/battle/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return BattleChatScreen(surpriseId: id);
        },
      ),
      GoRoute(
        path: '/shell/deliberation',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const _PlaceholderScreen(title: 'Deliberation');
          }
          return JudgeDeliberationScreen(
            surpriseId: extra['surpriseId']! as String,
            judgeResponse: extra['response']! as JudgeResponse,
            creatorId: extra['creatorId']! as String,
          );
        },
      ),
      GoRoute(
        path: '/shell/reveal/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return _PlaceholderScreen(title: 'Reveal $id');
          }
          return RevealScreen(
            surpriseId: id,
            judgeResponse: extra['response']! as JudgeResponse,
            creatorId: extra['creatorId']! as String,
          );
        },
      ),
      GoRoute(
        path: '/shell/wink-plus',
        builder: (_, __) => const WinkPlusScreen(),
      ),
      GoRoute(
        path: '/shell/quest/create',
        builder: (_, __) => const QuestCreateScreen(),
      ),
      GoRoute(
        path: '/shell/quest/complete/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return QuestCompleteScreen(questId: id);
        },
      ),
      GoRoute(
        path: '/shell/quest/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return QuestProgressScreen(questId: id);
        },
      ),
      GoRoute(
        path: '/shell/battle-pass',
        builder: (_, __) => const BattlePassScreen(),
      ),
      GoRoute(
        path: '/shell/referral',
        builder: (_, __) => const ReferralScreen(),
      ),
      GoRoute(
        path: '/shell/collab-piece/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return AddCollabPieceScreen(surpriseId: id);
        },
      ),
      GoRoute(
        path: '/shell/collection',
        builder: (_, __) => const CollectionScreen(),
      ),
      GoRoute(
        path: '/shell/leaderboard',
        builder: (_, __) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/shell/timeline',
        builder: (_, __) => const TimelineScreen(),
      ),
      GoRoute(
        path: '/shell/treasure-archive',
        builder: (_, __) => const TreasureArchiveScreen(),
      ),
      GoRoute(
        path: '/shell/treasure-archive/:surpriseId',
        builder: (_, state) {
          final surpriseId = state.pathParameters['surpriseId']!;
          return TreasureDetailScreen(surpriseId: surpriseId);
        },
      ),
    ],
  );
});

class _ShellScaffold extends StatefulWidget {
  const _ShellScaffold({
    required this.matchedLocation,
    required this.currentIndex,
    required this.navigationShell,
  });

  final String matchedLocation;
  final int currentIndex;
  final StatefulNavigationShell navigationShell;

  @override
  State<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<_ShellScaffold> {
  DateTime? _lastBackPressAt;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isShellTabRoot {
    final loc = widget.matchedLocation;
    return loc == '/shell/home' ||
        loc == '/shell/vault' ||
        loc == '/shell/winks' ||
        loc == '/shell/profile';
  }

  void _handleBackPress() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final now = DateTime.now();
    final shouldExit = _lastBackPressAt != null &&
        now.difference(_lastBackPressAt!) <= _kAndroidExitBackWindow;

    if (shouldExit) {
      _lastBackPressAt = null;
      SystemNavigator.pop();
      return;
    }

    _lastBackPressAt = now;
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(_kAndroidExitBackPrompt),
        duration: _kAndroidExitBackWindow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final interceptRootBack = _isAndroid && _isShellTabRoot;
    return PopScope(
      canPop: !interceptRootBack,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !interceptRootBack) return;
        _handleBackPress();
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: WinkBottomNav(
          currentIndex: widget.currentIndex,
          onIndexTap: (i) {
            switch (i) {
              case 0:
                context.go('/shell/home');
                break;
              case 1:
                context.go('/shell/vault');
                break;
              case 2:
                context.go('/shell/winks');
                break;
              case 3:
                context.go('/shell/profile');
                break;
            }
          },
          onCenterTap: () => context.push('/shell/create'),
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.gradientColors(Theme.of(context).brightness),
          ),
        ),
        child: Center(
            child: Text(title, style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}
