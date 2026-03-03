import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

class BattleCard extends StatelessWidget {
  const BattleCard({
    super.key,
    required this.onInviteTap,
    this.height,
    this.compact = false,
  });

  final VoidCallback onInviteTap;
  final double? height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final targetHeight = height ?? (compact ? 194 : 214);

    return Container(
      constraints: BoxConstraints(minHeight: targetHeight),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.battleGradient(brightness),
        ),
        border: Border.all(color: AppTheme.premiumBorder30(brightness)),
        boxShadow: AppTheme.premiumElevation(brightness),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppTheme.homeGlowPink.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, compact ? 14 : 16, 16, compact ? 14 : 16),
            child: Row(
              children: [
                Expanded(
                  flex: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start a Battle',
                        style: GoogleFonts.poppins(
                          fontSize: compact ? 21 : 23,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.homeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Challenge a friend. Persuade. Win.',
                        style: GoogleFonts.poppins(
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.homeTextSecondary,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: compact ? 11 : 14),
                      _BattleActionButton(onTap: onInviteTap, compact: compact),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  flex: 9,
                  child: _MinimalBattleIconBlock(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleActionButton extends StatefulWidget {
  const _BattleActionButton({required this.onTap, required this.compact});

  final VoidCallback onTap;
  final bool compact;

  @override
  State<_BattleActionButton> createState() => _BattleActionButtonState();
}

class _BattleActionButtonState extends State<_BattleActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scale = _pressed ? 0.97 : (_hovered ? 1.015 : 1.0);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppTheme.homeCtaNavyGradient(brightness),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              boxShadow: [
                if (_hovered)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(999),
                splashColor: Colors.white.withValues(alpha: 0.12),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact ? 16 : 18,
                    vertical: widget.compact ? 9 : 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.flash_on_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Invite to Battle',
                        style: GoogleFonts.poppins(
                          fontSize: widget.compact ? 14 : 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MinimalBattleIconBlock extends StatelessWidget {
  const _MinimalBattleIconBlock();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 124,
        height: 124,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              const Icon(
                Icons.sports_martial_arts_rounded,
                size: 34,
                color: Color(0xFFC9C4DB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
