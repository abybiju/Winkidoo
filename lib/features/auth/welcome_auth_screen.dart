import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

// --- Constants (mockup colors and sizes) ---

const Color _kNavyTop = Color(0xFF0F172A);
const Color _kPlumBottom = Color(0xFF1B1030);
const Color _kPlum = Color(0xFF6D2E8C);
const Color _kSurfaceDark = Color(0xFF1E293B);
const double _kInputHeight = 52.0;
const double _kRadius = 16.0;

const String _kBackgroundAsset = 'assets/images/welcomepage_background.png';
const String _kGoogleLogoAsset = 'assets/images/google_logo.png';
const String _kAppleLogoAsset = 'assets/images/apple_logo.png';
const String _kFacebookLogoAsset = 'assets/images/facebook_logo.png';
// Facebook brand blue for the button.
const Color _kFacebookBlue = Color(0xFF1877F2);

/// Welcome + Auth screen: email continue → login, Sign In → login, Google/Apple → Supabase OAuth.
class WelcomeAuthScreen extends ConsumerStatefulWidget {
  const WelcomeAuthScreen({super.key});

  @override
  ConsumerState<WelcomeAuthScreen> createState() => _WelcomeAuthScreenState();
}

class _WelcomeAuthScreenState extends ConsumerState<WelcomeAuthScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  bool _continuePressed = false;
  bool _isLoading = false;
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
    _emailController.dispose();
    super.dispose();
  }

  void _goToLogin({String? email}) {
    if (email != null && email.isNotEmpty) {
      context.go('/login', extra: {'email': email});
    } else {
      context.go('/login');
    }
  }

  Future<void> _onContinue() async {
    final email = _emailController.text.trim();
    _goToLogin(email: email);
  }

  Future<void> _onSignInTap() async {
    _goToLogin();
  }

  Future<void> _onGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onAppleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithOAuth(
        OAuthProvider.apple,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onFacebookSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: full-screen background image
          Positioned.fill(
            child: Image.asset(
              _kBackgroundAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_kNavyTop, _kPlumBottom],
                  ),
                ),
              ),
            ),
          ),
          // Layer 2: optional radial glow overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    _kPlum.withValues(alpha: 0.12),
                    _kPlum.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Layer 3: content with fade-in
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
                        const SizedBox(height: 24),
                        _buildSubtitle(),
                        const SizedBox(height: 32),
                        _buildEmailField(),
                        const SizedBox(height: 24),
                        _buildContinueButton(),
                        const SizedBox(height: 24),
                        _buildDivider(),
                        const SizedBox(height: 24),
                        _buildSocialButtons(),
                        const SizedBox(height: 32),
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
      'Sign in or\nCreate your vault',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 31,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Sync with your partner to reveal surprises.',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 16,
        color: Colors.white.withValues(alpha: 0.75),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      height: _kInputHeight,
      decoration: BoxDecoration(
        color: _kSurfaceDark,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(
          color: _kPlum.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: 'Email',
          hintStyle: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _continuePressed = true),
      onTapUp: (_) => setState(() => _continuePressed = false),
      onTapCancel: () => setState(() => _continuePressed = false),
      onTap: _isLoading ? null : _onContinue,
      child: AnimatedScale(
        scale: _continuePressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: _kInputHeight,
          decoration: BoxDecoration(
            color: _kPlum,
            borderRadius: BorderRadius.circular(_kRadius),
            boxShadow: [
              BoxShadow(
                color: _kPlum.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'Continue',
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

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.2),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.2),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        _WelcomeButton(
          onPressed: _isLoading ? () {} : _onGoogleSignIn,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          label: 'Continue with Google',
          leading: _buildGoogleLogo(),
        ),
        const SizedBox(height: 12),
        _WelcomeButton(
          onPressed: _isLoading ? () {} : _onFacebookSignIn,
          backgroundColor: _kFacebookBlue,
          foregroundColor: Colors.white,
          label: 'Continue with Facebook',
          leading: _buildFacebookLogo(),
        ),
        const SizedBox(height: 12),
        _WelcomeButton(
          onPressed: _isLoading ? () {} : _onAppleSignIn,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          label: 'Continue with Apple',
          leading: _buildAppleLogo(),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleLogo() {
    return Image.asset(
      _kGoogleLogoAsset,
      width: 22,
      height: 22,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.g_mobiledata_rounded,
        size: 22,
        color: Colors.black,
      ),
    );
  }

  Widget _buildAppleLogo() {
    return Image.asset(
      _kAppleLogoAsset,
      width: 22,
      height: 22,
      fit: BoxFit.contain,
      color: Colors.white,
      errorBuilder: (_, __, ___) => Icon(
        Icons.apple,
        size: 22,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFacebookLogo() {
    return Image.asset(
      _kFacebookLogoAsset,
      width: 22,
      height: 22,
      fit: BoxFit.contain,
      color: Colors.white,
      errorBuilder: (_, __, ___) => Text(
        'f',
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'By continuing you agree to our Terms and Privacy Policy.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _isLoading ? null : _onSignInTap,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              children: [
                const TextSpan(text: 'Already have an account? '),
                TextSpan(
                  text: 'Sign In',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable rounded button for social / primary actions.
class _WelcomeButton extends StatelessWidget {
  const _WelcomeButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.label,
    this.icon,
    this.leading,
    this.border,
  });

  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final String label;
  final IconData? icon;
  /// Custom leading widget (e.g. Google logo image); takes precedence over [icon].
  final Widget? leading;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final leadingWidget = leading ?? (icon != null ? Icon(icon, size: 22, color: foregroundColor) : null);
    return SizedBox(
      width: double.infinity,
      height: _kInputHeight,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(_kRadius),
          border: border,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_kRadius),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(_kRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingWidget != null) ...[
                    leadingWidget,
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
      ),
    );
  }
}
