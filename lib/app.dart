import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/error_screen.dart';
import 'package:winkidoo/features/auth/login_screen.dart';
import 'package:winkidoo/features/auth/couple_link_screen.dart';
import 'package:winkidoo/core/layout/responsive_vault_shell.dart';
import 'package:winkidoo/features/vault/realtime_surprises_subscription.dart';
import 'package:winkidoo/providers/auth_provider.dart';
import 'package:winkidoo/providers/couple_provider.dart';
import 'package:winkidoo/features/onboarding/onboarding_screen.dart';
import 'package:winkidoo/providers/onboarding_provider.dart';
import 'package:winkidoo/providers/theme_provider.dart';

class WinkidooApp extends ConsumerWidget {
  const WinkidooApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Winkidoo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: ref.watch(authStateProvider).when(
            data: (session) {
              if (session == null) return const LoginScreen();
              final onboardingComplete = ref.watch(onboardingCompleteProvider);
              if (!onboardingComplete) {
                return OnboardingScreen(
                  onComplete: () {},
                );
              }
              return ref.watch(coupleProvider).when(
                    data: (couple) {
                      if (couple == null) {
                        return const CoupleLinkScreen();
                      }
                      return const RealtimeSurprisesSubscription(
                        child: ResponsiveVaultShell(),
                      );
                    },
                    loading: () => const _LoadingScreen(),
                    error: (e, _) => ErrorScreen(
                      message: 'Could not load your couple. Tap to try again.',
                      onRetry: () => ref.invalidate(coupleProvider),
                      onBack: () => ref.invalidate(coupleProvider),
                    ),
                  );
            },
            loading: () => const _LoadingScreen(),
            error: (_, __) => ErrorScreen(
              message: 'Could not sign in. Tap to try again.',
              onRetry: () => ref.invalidate(authStateProvider),
              onBack: () => ref.invalidate(authStateProvider),
            ),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.gradientColors(Theme.of(context).brightness),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      ),
    );
  }
}
