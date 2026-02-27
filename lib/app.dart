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
    routerRefreshNotifier.update(authLoading, authenticated, onboarding, hasCouple);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRouterState());
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupPush());
  }

  void _setupPush() {
    final client = Supabase.instance.client;
    PushService.onTokenRefresh(client);
    final session = ref.read(authStateProvider).valueOrNull;
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
    final type = data['type'] as String?;
    if (type == 'season_launch') {
      ref.read(goRouterProvider).go('/shell/create');
      return;
    }
    final surpriseId = data['surprise_id'] as String?;
    if (surpriseId == null || surpriseId.isEmpty) return;
    ref.read(goRouterProvider).go('/shell/battle/$surpriseId');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      _updateRouterState();
      final session = next.valueOrNull;
      if (session != null) {
        PushService.register(Supabase.instance.client, session.user.id);
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
