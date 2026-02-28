import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

const String _kBackgroundAsset = 'assets/images/welcomepage_background.png';
const double _kButtonHeight = 52.0;
const double _kRadius = 16.0;

/// Emotional welcome: Winkidoo + tagline. Two actions only — Sign In | Create Account.
/// No email field. Auth form (with toggle) lives on /login.
class WelcomeAuthScreen extends ConsumerStatefulWidget {
  const WelcomeAuthScreen({super.key});

  @override
  ConsumerState<WelcomeAuthScreen> createState() => _WelcomeAuthScreenState();
}

class _WelcomeAuthScreenState extends ConsumerState<WelcomeAuthScreen>
    with SingleTickerProviderStateMixin {
  bool _signInPressed = false;
  bool _createAccountPressed = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              _kBackgroundAsset,
              fit: BoxFit.cover,
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
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    AppTheme.plum.withValues(alpha: 0.12),
                    AppTheme.plum.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.sizeOf(context).height -
                        MediaQuery.paddingOf(context).top -
                        MediaQuery.paddingOf(context).bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80),
                        _buildTitle(),
                        const SizedBox(height: 12),
                        _buildSubtitle(),
                        const SizedBox(height: 48),
                        _buildSignInButton(),
                        const SizedBox(height: 16),
                        _buildCreateAccountButton(),
                        const SizedBox(height: 40),
                        _buildFooter(),
                        const SizedBox(height: 24),
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

  Widget _buildTitle() {
    return Text(
      'Winkidoo',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Unlock the surprise.',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 18,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildSignInButton() {
    return _WelcomePrimaryButton(
      label: 'Sign In',
      pressed: _signInPressed,
      onTapDown: () => setState(() => _signInPressed = true),
      onTapUp: () => setState(() => _signInPressed = false),
      onTapCancel: () => setState(() => _signInPressed = false),
      onTap: () => context.go('/login', extra: {'mode': 'signIn'}),
    );
  }

  Widget _buildCreateAccountButton() {
    return _WelcomeOutlinedButton(
      label: 'Create Account',
      pressed: _createAccountPressed,
      onTapDown: () => setState(() => _createAccountPressed = true),
      onTapUp: () => setState(() => _createAccountPressed = false),
      onTapCancel: () => setState(() => _createAccountPressed = false),
      onTap: () => context.go('/login', extra: {'mode': 'signUp'}),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'By continuing you agree to our Terms and Privacy Policy.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _WelcomePrimaryButton extends StatelessWidget {
  const _WelcomePrimaryButton({
    required this.label,
    required this.pressed,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.onTap,
  });

  final String label;
  final bool pressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      onTap: onTap,
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: _kButtonHeight,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppTheme.primaryPink,
            borderRadius: BorderRadius.circular(_kRadius),
            boxShadow: [AppTheme.pinkGlow],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeOutlinedButton extends StatelessWidget {
  const _WelcomeOutlinedButton({
    required this.label,
    required this.pressed,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.onTap,
  });

  final String label;
  final bool pressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      onTap: onTap,
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: _kButtonHeight,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(_kRadius),
            border: Border.all(
              color: AppTheme.plum.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
