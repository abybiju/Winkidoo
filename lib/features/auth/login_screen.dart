import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/providers/supabase_provider.dart';

const double _kInputHeight = 52.0;
const double _kRadius = 16.0;

/// Single auth form: Sign In | Sign Up toggle, same layout.
/// Default border = plum 30%, focus = primaryPink. Toggle: secondary text 60%, action word brighter.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialEmail, this.initialSignUp});

  final String? initialEmail;
  /// When true, form starts in sign-up mode (Create account).
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
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
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
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
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
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.bgTop, AppTheme.bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTitle(),
                    const SizedBox(height: 8),
                    Text(
                      'Unlock the surprise.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                    _buildToggle(),
                    const SizedBox(height: 32),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildSocialButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    ),
    );
  }

  Widget _buildTitle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 160,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPink.withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
        Text(
          'Winkidoo',
          style: GoogleFonts.poppins(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryPink,
          ),
        ),
      ],
    );
  }

  static final _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_kRadius),
    borderSide: BorderSide(color: AppTheme.plum.withValues(alpha: 0.3)),
  );
  static final _inputBorderFocused = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_kRadius),
    borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
  );

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.surface1,
        hintText: 'Email',
        hintStyle: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        enabledBorder: _inputBorder,
        focusedBorder: _inputBorderFocused,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Enter email';
        if (!v.contains('@')) return 'Enter a valid email';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.surface1,
        hintText: '••••••••',
        hintStyle: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        enabledBorder: _inputBorder,
        focusedBorder: _inputBorderFocused,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter password';
        if (_isSignUp && v.length < 6) return 'At least 6 characters';
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return Semantics(
      label: _isSignUp ? 'Create account' : 'Sign in',
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: _kInputHeight,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryPink,
            borderRadius: BorderRadius.circular(_kRadius),
            boxShadow: [AppTheme.pinkGlow],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_kRadius),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isSignUp ? 'Create account' : 'Sign in',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return GestureDetector(
      onTap: _isLoading ? null : () => setState(() => _isSignUp = !_isSignUp),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          children: [
            TextSpan(
              text: _isSignUp ? 'Already have an account? ' : 'No account? ',
            ),
            TextSpan(
              text: _isSignUp ? 'Sign in' : 'Sign up',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.white.withValues(alpha: 0.2), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.white.withValues(alpha: 0.2), thickness: 1),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        _SocialButton(
          label: 'Continue with Google',
          onPressed: _isLoading ? () {} : _onGoogleSignIn,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: 'Continue with Apple',
          onPressed: _isLoading ? () {} : _onAppleSignIn,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.border,
  });

  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _kInputHeight,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_kRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(_kRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_kRadius),
              border: border,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: foregroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
