import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/features/auth/login_screen.dart';
import 'package:winkidoo/features/auth/couple_link_screen.dart';
import 'package:winkidoo/features/vault/realtime_surprises_subscription.dart';
import 'package:winkidoo/features/vault/vault_list_screen.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';

class WinkidooApp extends ConsumerWidget {
  const WinkidooApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Winkidoo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: ref.watch(authStateProvider).when(
            data: (session) {
              if (session == null) return const LoginScreen();
              return ref.watch(coupleProvider).when(
                    data: (couple) {
                      if (couple == null) {
                        return const CoupleLinkScreen();
                      }
                      return const RealtimeSurprisesSubscription(
                        child: VaultListScreen(),
                      );
                    },
                    loading: () => const _LoadingScreen(),
                    error: (e, _) => const CoupleLinkScreen(),
                  );
            },
            loading: () => const _LoadingScreen(),
            error: (_, __) => const LoginScreen(),
          ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundStart,
              AppTheme.backgroundEnd,
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      ),
    );
  }
}
