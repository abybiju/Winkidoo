import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

const double _kFieldHeight = 58.0;
const double _kRadius = 20.0;

/// Single auth form with premium styling and mode toggle.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialEmail, this.initialSignUp});

  final String? initialEmail;
  final bool? initialSignUp;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _isSignUp = widget.initialSignUp ?? false;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      if (_isSignUp) {
        await client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check your email to confirm sign up!'),
              backgroundColor: AppTheme.primary,
            ),
          );
        }
      } else {
        await client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConstants.oAuthRedirectUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppTheme.error),
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
        redirectTo: AppConstants.oAuthRedirectUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppTheme.error),
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
        redirectTo: AppConstants.oAuthRedirectUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onForgotPassword() async {
    if (_isLoading) return;
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a valid email first.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: AppConstants.oAuthRedirectUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent.'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.bgTop, AppTheme.bgBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 1.12,
                    colors: [
                      AppTheme.primaryPink.withValues(alpha: 0.13),
                      AppTheme.plum.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: isWide ? 520 : double.infinity),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _InlineLogo(),
                                const SizedBox(height: 26),
                                _PremiumInput(
                                  controller: _emailController,
                                  hintText: 'Enter your email',
                                  keyboardType: TextInputType.emailAddress,
                                  icon: Icons.person_rounded,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Enter email';
                                    }
                                    if (!v.contains('@')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                _PremiumInput(
                                  controller: _passwordController,
                                  hintText: _isSignUp
                                      ? 'Create a password'
                                      : 'Enter password',
                                  icon: Icons.lock_rounded,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color:
                                          Colors.white.withValues(alpha: 0.75),
                                    ),
                                    tooltip: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Enter password';
                                    }
                                    if (_isSignUp && v.length < 6) {
                                      return 'At least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                if (!_isSignUp) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed:
                                          _isLoading ? null : _onForgotPassword,
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.primaryPink,
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                      ),
                                      child: Text(
                                        'Forgot password?',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                _PrimaryAuthButton(
                                  label: _isSignUp ? 'Sign Up' : 'Log In',
                                  isLoading: _isLoading,
                                  onPressed: _isLoading ? null : _submit,
                                ),
                                const SizedBox(height: 12),
                                _ModeToggleText(
                                  isSignUp: _isSignUp,
                                  disabled: _isLoading,
                                  onTap: () =>
                                      setState(() => _isSignUp = !_isSignUp),
                                ),
                                const SizedBox(height: 20),
                                _DividerText(),
                                const SizedBox(height: 16),
                                _SocialButton(
                                  label: 'Continue with Google',
                                  iconAsset:
                                      'assets/images/google logo png.png',
                                  onPressed:
                                      _isLoading ? null : _onGoogleSignIn,
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF321640),
                                  iconScale: 1.28,
                                  iconFit: BoxFit.cover,
                                  iconNudgeX: 1.0,
                                ),
                                const SizedBox(height: 12),
                                _SocialButton(
                                  label: 'Continue with Apple',
                                  iconAsset: 'assets/images/apple logo png.png',
                                  onPressed: _isLoading ? null : _onAppleSignIn,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.03),
                                  foregroundColor: Colors.white,
                                  border: Border.all(
                                    color: AppTheme.primaryPink
                                        .withValues(alpha: 0.35),
                                  ),
                                  iconScale: 1.2,
                                  iconNudgeX: -0.5,
                                ),
                                const SizedBox(height: 12),
                                _SocialButton(
                                  label: 'Continue with Facebook',
                                  iconAsset: 'assets/images/facebook_logo.png',
                                  onPressed:
                                      _isLoading ? null : _onFacebookSignIn,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.03),
                                  foregroundColor: Colors.white,
                                  border: Border.all(
                                    color: AppTheme.primaryPink
                                        .withValues(alpha: 0.35),
                                  ),
                                  iconScale: 1.2,
                                  iconNudgeX: 0.0,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: Colors.white.withValues(alpha: 0.66),
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineLogo extends StatelessWidget {
  const _InlineLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/winkidoo new logo.png',
            width: 38,
            height: 38,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD739),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'W',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: const Color(0xFF5A2C00),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Winkidoo',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _PremiumInput extends StatelessWidget {
  const _PremiumInput({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  static final _restBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_kRadius),
    borderSide: BorderSide(color: AppTheme.primaryPink.withValues(alpha: 0.35)),
  );

  static final _focusBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_kRadius),
    borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.inter(fontSize: 20, color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          fontSize: 20,
          color: Colors.white.withValues(alpha: 0.72),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: AppTheme.primaryPink, size: 28),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: _restBorder,
        focusedBorder: _focusBorder,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
        ),
      ),
    );
  }
}

class _PrimaryAuthButton extends StatefulWidget {
  const _PrimaryAuthButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  State<_PrimaryAuthButton> createState() => _PrimaryAuthButtonState();
}

class _PrimaryAuthButtonState extends State<_PrimaryAuthButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final scale = _pressed ? 0.972 : 1.0;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: _kFieldHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_kRadius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: enabled
                    ? (_hovered
                        ? const [Color(0xFFFFF18A), Color(0xFFFFD84D)]
                        : const [Color(0xFFFFE96A), Color(0xFFFFCC31)])
                    : const [Color(0xFFE4D18A), Color(0xFFB9A669)],
              ),
              border: Border.all(
                color: const Color(0xFFFFF4B5)
                    .withValues(alpha: _hovered ? 0.55 : 0.42),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFCF40)
                      .withValues(alpha: enabled ? 0.48 : 0.24),
                  blurRadius: _hovered ? 24 : 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5A3A00),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggleText extends StatefulWidget {
  const _ModeToggleText({
    required this.isSignUp,
    required this.disabled,
    required this.onTap,
  });

  final bool isSignUp;
  final bool disabled;
  final VoidCallback onTap;

  @override
  State<_ModeToggleText> createState() => _ModeToggleTextState();
}

class _ModeToggleTextState extends State<_ModeToggleText> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.isSignUp ? 'Log In' : 'Sign Up';
    final prefix =
        widget.isSignUp ? 'Already have an account? ' : 'Need an account? ';
    final actionColor =
        _hovered ? Colors.white : AppTheme.primaryPink.withValues(alpha: 0.95);

    return MouseRegion(
      cursor:
          widget.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.disabled ? null : widget.onTap,
        child: Text.rich(
          TextSpan(
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.72),
            ),
            children: [
              TextSpan(text: prefix),
              TextSpan(
                text: action,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: actionColor,
                  decoration:
                      _hovered ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _DividerText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.22),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.22),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatefulWidget {
  const _SocialButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.border,
    this.iconAsset,
    this.iconScale = 1.0,
    this.iconFit = BoxFit.contain,
    this.iconNudgeX = 0,
  });

  final String label;
  final String? iconAsset;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Border? border;
  final double iconScale;
  final BoxFit iconFit;
  final double iconNudgeX;

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: _kFieldHeight,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(_kRadius),
          border: widget.border,
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(_kRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(widget.iconNudgeX, 0),
                          child: _buildLeading(),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: widget.foregroundColor,
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

  Widget _buildLeading() {
    if (widget.iconAsset != null) {
      return Transform.scale(
        scale: widget.iconScale,
        child: ClipRect(
          child: SizedBox(
            width: 24,
            height: 24,
            child: Image.asset(
              widget.iconAsset!,
              fit: widget.iconFit,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Icon(
                Icons.circle,
                size: 24,
                color: widget.foregroundColor,
              ),
            ),
          ),
        ),
      );
    }
    return Icon(Icons.circle, size: 24, color: widget.foregroundColor);
  }
}
