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
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.vaultHeroGradient(brightness),
        ),
        border: Border.all(color: AppTheme.premiumBorder30(brightness)),
        boxShadow: AppTheme.elevation3(brightness),
      ),
      child: Stack(
        children: [
          // Subtle glow from bottom
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppTheme.homeGlowPink.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Left vignette for depth
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppTheme.vaultDramaVignette.withValues(
                        alpha: brightness == Brightness.dark ? 0.36 : 0.16,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                18, compact ? 14 : 18, 18, compact ? 14 : 18),
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
                        style: GoogleFonts.inter(
                          fontSize: compact ? 22 : 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.homeTextPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Challenge friends. Master words. Claim victory.',
                        style: GoogleFonts.inter(
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.homeTextSecondary,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      _BattleActionButton(
                          onTap: onInviteTap, compact: compact),
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

class _BattleActionButtonState extends State<_BattleActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: AppTheme.microDuration,
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 0.0,
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          final scale = 1.0 - (_pressController.value * 0.04);
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF8C42), Color(0xFFFF6200)],
            ),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6200).withValues(alpha: 0.40),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFFFF8C42).withValues(alpha: 0.30),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 18 : 20,
              vertical: widget.compact ? 10 : 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.flash_on_rounded,
                  color: Color(0xFF4A2800),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Invite to Battle',
                  style: GoogleFonts.poppins(
                    fontSize: widget.compact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: const Color(0xFF4A2800),
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

class _MinimalBattleIconBlock extends StatelessWidget {
  const _MinimalBattleIconBlock();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 118,
        height: 118,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: brightness == Brightness.dark
              ? AppTheme.glassFill
              : const Color(0x0A000000),
          border: Border.all(
            color: brightness == Brightness.dark
                ? AppTheme.glassBorderSubtle
                : const Color(0x14000000),
          ),
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: brightness == Brightness.dark
                      ? AppTheme.glassFill
                      : const Color(0x0A000000),
                ),
              ),
              Icon(
                Icons.sports_martial_arts_rounded,
                size: 32,
                color: brightness == Brightness.dark
                    ? AppTheme.textMuted
                    : AppTheme.lightTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
