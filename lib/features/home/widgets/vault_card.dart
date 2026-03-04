import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

class VaultCard extends StatelessWidget {
  const VaultCard({
    super.key,
    required this.currentStreakWeeks,
    required this.waitingCount,
    required this.onEnterVault,
    this.height,
    this.compact = false,
  });

  final int currentStreakWeeks;
  final int waitingCount;
  final VoidCallback onEnterVault;
  final double? height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final targetHeight = height ?? (compact ? 136 : 152);

    return Container(
      constraints: BoxConstraints(minHeight: targetHeight),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.vaultHeroGradient(brightness),
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
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.homeGlowOrange.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppTheme.vaultDramaVignette.withValues(
                        alpha: brightness == Brightness.dark ? 0.44 : 0.2,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your Vault',
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.homeTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const _VaultGlyph(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$currentStreakWeeks-week streak',
                            style: GoogleFonts.poppins(
                              fontSize: compact ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.homeTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$waitingCount surprises waiting',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: compact ? 13 : 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.homeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _EnterVaultButton(
                      onTap: onEnterVault,
                      compact: compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VaultGlyph extends StatelessWidget {
  const _VaultGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: const Icon(
        Icons.inventory_2_rounded,
        color: Color(0xFFC9C4DB),
        size: 28,
      ),
    );
  }
}

class _EnterVaultButton extends StatefulWidget {
  const _EnterVaultButton({required this.onTap, required this.compact});

  final VoidCallback onTap;
  final bool compact;

  @override
  State<_EnterVaultButton> createState() => _EnterVaultButtonState();
}

class _EnterVaultButtonState extends State<_EnterVaultButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.97 : (_hovered ? 1.015 : 1.0);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 130),
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
              color: Colors.white.withValues(alpha: 0.07),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              boxShadow: [
                if (_hovered)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: widget.onTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact ? 12 : 14,
                    vertical: widget.compact ? 9 : 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Enter Vault',
                        style: GoogleFonts.poppins(
                          fontSize: widget.compact ? 14 : 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.homeTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: Color(0xFFC9C4DB),
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
