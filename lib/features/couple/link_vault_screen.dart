import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

// --- Constants ---

const Color _kNavyTop = AppTheme.bgTop;
const Color _kPlumBottom = AppTheme.bgBottom;
const Color _kPlum = AppTheme.secondaryViolet;
const Color _kSurfaceDark = AppTheme.surface2;

const double _kCardRadius = 20.0;
const double _kButtonHeight = 52.0;
const double _kRadius = 16.0;
const double _kPadding = 24.0;
const double _kSectionSpacing = 32.0;
const double _kTopPadding = 80.0;
const double _kFooterSpacing = 40.0;

/// UI-only "Link your vault" pairing screen. No Supabase, navigation, or providers.
class LinkVaultScreen extends StatefulWidget {
  const LinkVaultScreen({super.key});

  @override
  State<LinkVaultScreen> createState() => _LinkVaultScreenState();
}

class _LinkVaultScreenState extends State<LinkVaultScreen> {
  bool _createButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Layer 1: linear gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_kNavyTop, _kPlumBottom],
                ),
              ),
            ),
          ),
          // Layer 2: radial glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    _kPlum.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                _kPadding,
                _kTopPadding,
                _kPadding,
                _kPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: _kSectionSpacing),
                  _buildCreateCard(),
                  const SizedBox(height: _kSectionSpacing),
                  _buildJoinCard(),
                  const SizedBox(height: _kFooterSpacing),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Link your vault',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 31,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Invite your partner and start hiding surprises.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateCard() {
    return _VaultOptionCard(
      title: 'Create a new vault',
      description: "We'll generate a private invite code for your partner.",
      child: GestureDetector(
        onTapDown: (_) => setState(() => _createButtonPressed = true),
        onTapUp: (_) => setState(() => _createButtonPressed = false),
        onTapCancel: () => setState(() => _createButtonPressed = false),
        child: AnimatedScale(
          scale: _createButtonPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            height: _kButtonHeight,
            decoration: BoxDecoration(
              color: _kPlum,
              borderRadius: BorderRadius.circular(_kRadius),
              boxShadow: [
                BoxShadow(
                  color: _kPlum.withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'Create Vault',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinCard() {
    return _VaultOptionCard(
      title: 'Join with a code',
      description: 'Enter the invite code your partner shared.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: _kButtonHeight,
            decoration: BoxDecoration(
              color: _kNavyTop,
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(
                color: _kPlum.withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Invite Code',
                hintStyle: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: _kButtonHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(
                color: _kPlum.withValues(alpha: 0.5),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'Join Vault',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPlum,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'One vault. One partner. Infinite persuasion.',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }
}

class _VaultOptionCard extends StatelessWidget {
  const _VaultOptionCard({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_kPadding),
      decoration: BoxDecoration(
        color: _kSurfaceDark,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(
          color: _kPlum.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
