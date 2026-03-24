import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/core/widgets/cosmic_background.dart';

const double _kCardRadius = 24.0;
const double _kButtonHeight = 52.0;
const double _kRadius = 16.0;
const double _kPadding = 24.0;
const double _kSectionSpacing = 30.0;
const double _kTopPadding = 100.0;
const double _kCardInnerSpacing = 20.0;
const double _kBottomMicrocopySpacing = 40.0;

/// Premium "Vault Sealed" success screen. UI only; receives [inviteCode] from route.
class VaultSealedScreen extends StatefulWidget {
  const VaultSealedScreen({super.key, required this.inviteCode});

  final String inviteCode;

  @override
  State<VaultSealedScreen> createState() => _VaultSealedScreenState();
}

class _VaultSealedScreenState extends State<VaultSealedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _shareButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _formatCode(String code) {
    if (code.length == 8) {
      return '${code.substring(0, 4)}\u2013${code.substring(4)}';
    }
    return code;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CosmicBackground(
        glowColor: AppTheme.secondaryViolet,
        child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                _kPadding,
                _kTopPadding,
                _kPadding,
                _kPadding,
              ),
              child: FadeTransition(
                opacity: _animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.97, end: 1.0).animate(_animation),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildTopLabel(),
                      const SizedBox(height: _kSectionSpacing),
                      _buildHeadline(),
                      const SizedBox(height: _kSectionSpacing),
                      _buildSubtext(),
                      const SizedBox(height: _kSectionSpacing),
                      _buildHeroCard(),
                      const SizedBox(height: _kBottomMicrocopySpacing),
                      _buildBottomMicrocopy(),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ),
    );
  }

  Widget _buildTopLabel() {
    return Text(
      'VAULT SEALED',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 12,
        letterSpacing: 1.6,
        color: Colors.white.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _buildHeadline() {
    return Text(
      'Your private vault is ready.',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSubtext() {
    return Text(
      'Share this code with your partner to link.',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 16,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_kPadding),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(
          color: AppTheme.secondaryViolet.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(
            _formatCode(widget.inviteCode),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: _kCardInnerSpacing),
          _buildShareInviteButton(),
          const SizedBox(height: _kCardInnerSpacing),
          _buildCopyCodeButton(),
        ],
      ),
    );
  }

  Widget _buildShareInviteButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _shareButtonPressed = true),
      onTapUp: (_) => setState(() => _shareButtonPressed = false),
      onTapCancel: () => setState(() => _shareButtonPressed = false),
      child: AnimatedScale(
        scale: _shareButtonPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: _kButtonHeight,
          decoration: BoxDecoration(
            color: AppTheme.secondaryViolet,
            borderRadius: BorderRadius.circular(_kRadius),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryViolet.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'Share Invite',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCopyCodeButton() {
    return Container(
      height: _kButtonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(
          color: AppTheme.secondaryViolet.withValues(alpha: 0.5),
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.copy_rounded,
            size: 20,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Text(
            'Copy Code',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomMicrocopy() {
    return Text(
      'Only one partner can link to this vault.',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.45),
      ),
    );
  }
}
