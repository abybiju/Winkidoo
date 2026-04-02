import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/providers/onboarding_provider.dart';
import 'package:winkidoo/providers/theme_provider.dart';
import 'package:winkidoo/router/app_router.dart';
import 'package:winkidoo/services/push_service.dart';
import 'package:winkidoo/services/revenuecat_service.dart';

class WinkidooApp extends ConsumerStatefulWidget {
  const WinkidooApp({super.key});

  @override
  ConsumerState<WinkidooApp> createState() => _WinkidooAppState();
}

class _WinkidooAppState extends ConsumerState<WinkidooApp> {
  void _updateRouterState() {
    final auth = ref.read(authStateProvider);
    final onboarding = ref.read(onboardingCompleteProvider);
    final couple = ref.read(coupleProvider);
    final authLoading = auth.isLoading;
    final authenticated = auth.hasValue ? (auth.value != null) : null;
    final hasCouple = couple.hasValue ? (couple.value != null) : null;
    final isCoupleLinked = couple.hasValue ? (couple.value?.isLinked ?? false) : null;
    routerRefreshNotifier.update(authLoading, authenticated, onboarding, hasCouple, isCoupleLinked: isCoupleLinked);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRouterState());
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupPush());
    _setupOAuthDeepLinks();
  }

  /// Handle OAuth redirect (e.g. Google sign-in) when Supabase redirects to winkidoo://auth/callback.
  void _setupOAuthDeepLinks() {
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((Uri uri) {
      if (uri.host == 'auth' && uri.pathSegments.contains('callback')) {
        Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    });
    appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null && uri.host == 'auth' && uri.pathSegments.contains('callback')) {
        Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    });
  }

  void _setupPush() {
    final client = Supabase.instance.client;
    PushService.onTokenRefresh(client);
    final session = ref.read(authStateProvider).value;
    if (session != null) {
      PushService.register(client, session.user.id);
    }
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateFromPush(message.data);
    });
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) _navigateFromPush(message.data);
    });
  }

  void _navigateFromPush(Map<String, dynamic> data) {
    final router = ref.read(goRouterProvider);
    final type = data['type'] as String?;
    switch (type) {
      case 'season_launch':
        router.go('/shell/create');
        return;
      case 'dare':
      case 'dare_result':
        router.go('/shell/home');
        return;
      case 'mini_game':
      case 'mini_game_result':
        router.go('/shell/home');
        return;
      case 'campaign':
        final campaignId = data['campaign_id'] as String?;
        if (campaignId != null) {
          router.go('/shell/campaign/$campaignId');
        } else {
          router.go('/shell/campaigns');
        }
        return;
      case 'custom_judge_ready':
        router.go('/shell/my-judges');
        return;
    }
    // Fallback: battle notification (surprise_id based)
    final surpriseId = data['surprise_id'] as String?;
    if (surpriseId == null || surpriseId.isEmpty) return;
    router.go('/shell/battle/$surpriseId');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      _updateRouterState();
      final session = next.value;
      if (session != null) {
        PushService.register(Supabase.instance.client, session.user.id);
        RevenueCatService.configureUser(session.user.id);
      }
    });
    ref.listen(coupleProvider, (_, __) => _updateRouterState());
    ref.listen(onboardingCompleteProvider, (_, __) => _updateRouterState());

    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Winkidoo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
