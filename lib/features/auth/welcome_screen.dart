import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

const double _kPillRadius = 999.0;

/// Premium welcome/onboarding entry: hero section + auth actions.
/// Mimics a modern onboarding experience (e.g. Perplexity-style).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  static const Color _bottomBackground = Color(0xFF1E1E1E);
  static const Color _buttonDarkGrey = Color(0xFF2C2C2C);
  static const double _heroFraction = 0.48;
  static const double _horizontalPadding = 24.0;
  static const double _buttonGap = 12.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final topHeight = constraints.maxHeight * _heroFraction;
          final bottomHeight = constraints.maxHeight * (1 - _heroFraction);
          return Column(
            children: [
              SizedBox(
                height: topHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _HeroSection(),
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      right: 16,
                      child: SafeArea(
                        child: TextButton(
                          onPressed: () {
                            debugPrint('WelcomeScreen: Skip tapped');
                            _navigateToLogin(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: bottomHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Layer 1: robo image (portrait on mobile, landscape on web)
                    Image.asset(
                      kIsWeb
                          ? 'assets/images/welcome_robo_landscape.png'
                          : 'assets/images/welcome_robo_portrait.png',
                      fit: BoxFit.cover,
                    ),
                    // Layer 2: gradient fade into charcoal
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            _bottomBackground.withValues(alpha: 0.4),
                            _bottomBackground,
                          ],
                          stops: const [0.0, 0.45, 0.75],
                        ),
                      ),
                    ),
                    // Layer 3: content (logo, buttons, footer)
                    Container(
                      padding: EdgeInsets.only(
                        left: _horizontalPadding,
                        right: _horizontalPadding,
                        top: 24,
                        bottom: MediaQuery.paddingOf(context).bottom + 16,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LogoSection(),
                          const SizedBox(height: 32),
                          _AuthButton(
                            icon: Icons.apple,
                            label: 'Continue with Apple',
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            onPressed: () {
                              debugPrint('WelcomeScreen: Continue with Apple');
                              // TODO: Wire Supabase Apple sign-in
                            },
                          ),
                          const SizedBox(height: _buttonGap),
                          _AuthButton(
                            icon: Icons.g_mobiledata,
                            label: 'Continue with Google',
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            onPressed: () {
                              debugPrint('WelcomeScreen: Continue with Google');
                              // TODO: Wire Supabase Google sign-in
                            },
                          ),
                          const SizedBox(height: _buttonGap),
                          _AuthButton(
                            label: 'Continue with email',
                            backgroundColor: _buttonDarkGrey,
                            foregroundColor: Colors.white,
                            onPressed: () {
                              debugPrint('WelcomeScreen: Continue with email');
                              _navigateToLogin(context);
                            },
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  debugPrint('WelcomeScreen: Privacy policy');
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey.shade500,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  'Privacy policy',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              Text(
                                ' · ',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  debugPrint('WelcomeScreen: Terms of service');
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey.shade500,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  'Terms of service',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    context.go('/login');
  }
}

/// Top hero: gradient (or placeholder for future Rive/Lottie).
class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          // TODO: Replace with Rive/Lottie animation of the AI Judge wink
          child: Placeholder(
            color: AppTheme.primary.withValues(alpha: 0.3),
            fallbackHeight: 120,
            fallbackWidth: 120,
          ),
        ),
      ),
    );
  }
}

/// Logo + app name at top of bottom half.
class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.favorite_border,
          size: 48,
          color: Colors.white.withValues(alpha: 0.95),
        ),
        const SizedBox(height: 12),
        Text(
          'winkidoo',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

/// Full-width pill-shaped auth button; optional leading icon.
class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_kPillRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(_kPillRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 22, color: foregroundColor),
                  const SizedBox(width: 12),
                ],
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

