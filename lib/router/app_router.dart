import 'package:flutter/material.dart';
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
import 'package:winkidoo/models/judge_response.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/onboarding_provider.dart';

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
                            Color(0xFF0F172A),
                            Color(0xFF1B1030),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
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
                        Color(0xFF0F172A),
                        Color(0xFF1B1030),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
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
                        Color(0xFF0F172A),
                        Color(0xFF1B1030),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
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
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: WinkBottomNav(
              currentIndex: index,
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
