import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

const String _kBackgroundAsset = 'assets/images/background .png';
const double _kButtonHeight = 76.0;
const double _kButtonRadius = 999.0;

/// Premium first-screen hero with a single CTA.
/// Flow remains unchanged: Get Started -> /login.
class WelcomeAuthScreen extends ConsumerStatefulWidget {
  const WelcomeAuthScreen({super.key});

  @override
  ConsumerState<WelcomeAuthScreen> createState() => _WelcomeAuthScreenState();
}

class _WelcomeAuthScreenState extends ConsumerState<WelcomeAuthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final isDesktop = media.width >= 900;
    final horizontalPadding = isDesktop ? 56.0 : 24.0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              _kBackgroundAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.none,
              isAntiAlias: false,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.bgTop, AppTheme.bgBottom],
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(child: _HeroOverlays()),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      isDesktop ? 42 : 22,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Play Your Circle',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: isDesktop ? 74 : 44,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            color: Colors.white,
                            letterSpacing: -0.25,
                            shadows: const [
                              Shadow(
                                color: Color(0x55000000),
                                blurRadius: 12,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Play with friends, unlock vaults, collect wins.',
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: isDesktop ? 34 : 18,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                              color: Colors.white.withValues(alpha: 0.74),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _GetStartedButton(
                          onTap: () =>
                              context.go('/login', extra: {'mode': 'signUp'}),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroOverlays extends StatelessWidget {
  const _HeroOverlays();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.26),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 0.2),
                radius: 1.15,
                colors: [
                  AppTheme.primaryPink.withValues(alpha: 0.07),
                  AppTheme.plum.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 84,
          child: IgnorePointer(
            child: Center(
              child: Container(
                width: 380,
                height: 108,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF5CA8).withValues(alpha: 0.13),
                      Colors.transparent,
                    ],
                    radius: 0.82,
                  ),
                ),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GetStartedButton extends StatefulWidget {
  const _GetStartedButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed
        ? 0.973
        : _hovered
            ? 1.012
            : 1.0;
    final translateY = _pressed
        ? 1.0
        : _hovered
            ? -2.0
            : 0.0;

    return Semantics(
      button: true,
      label: 'Get started',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, translateY, 0),
              height: _kButtonHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_kButtonRadius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _hovered
                      ? const [Color(0xFFFFF18A), Color(0xFFFFD84D)]
                      : const [Color(0xFFFFE96A), Color(0xFFFFCC31)],
                ),
                border: Border.all(
                  color: const Color(0xFFFFF4B5)
                      .withValues(alpha: _hovered ? 0.55 : 0.42),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFCF40).withValues(
                      alpha: _hovered ? 0.56 : 0.46,
                    ),
                    blurRadius: _hovered ? 34 : 26,
                    spreadRadius: _hovered ? 1.5 : 0,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: 14,
                    right: 14,
                    top: 7,
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_kButtonRadius),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.25),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5A3A00),
                        letterSpacing: 0.2,
                        shadows: const [
                          Shadow(
                            color: Color(0x33FFFFFF),
                            blurRadius: 8,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
