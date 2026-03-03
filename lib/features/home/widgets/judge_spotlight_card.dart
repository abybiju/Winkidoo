import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/judge_asset_map.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/judge.dart';
import 'package:winkidoo/providers/user_profile_provider.dart';

class JudgeSpotlightCard extends ConsumerStatefulWidget {
  const JudgeSpotlightCard({
    super.key,
    required this.judge,
    required this.onExplore,
    this.height,
    this.compact = false,
  });

  final Judge judge;
  final VoidCallback onExplore;
  final double? height;
  final bool compact;

  @override
  ConsumerState<JudgeSpotlightCard> createState() => _JudgeSpotlightCardState();
}

class _JudgeSpotlightCardState extends ConsumerState<JudgeSpotlightCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final targetHeight = widget.height ?? (widget.compact ? 176 : 196);
    final gender = ref.watch(userProfileMetaProvider).gender;
    final judgeAsset = JudgeAssetResolver.resolveAvatarPath(
      judge: widget.judge,
      userGender: gender,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0.0, _hovered ? -1.5 : 0.0, 0.0),
        constraints: BoxConstraints(minHeight: targetHeight),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.spotlightGradient(brightness),
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
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppTheme.homeGlowPink.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                          'Judge Spotlight',
                          style: GoogleFonts.poppins(
                            fontSize: widget.compact ? 17 : 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.homeTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Meet ${widget.judge.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: widget.compact ? 20 : 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.homeTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.judge.tagline ??
                              'Feeling magical. Feeling judgey.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: widget.compact ? 14 : 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.homeTextSecondary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _OutlineButton(
                          onTap: widget.onExplore,
                          hovered: _hovered,
                          compact: widget.compact,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 9,
                    child: _JudgeGlyphBlock(
                      assetPath: judgeAsset,
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

class _JudgeGlyphBlock extends StatelessWidget {
  const _JudgeGlyphBlock({required this.assetPath});

  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        width: 118,
        height: 118,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Center(
          child: (assetPath ?? '').isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    assetPath!,
                    fit: BoxFit.cover,
                    width: 98,
                    height: 98,
                    errorBuilder: (_, __, ___) => _fallback(),
                  ),
                )
              : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() => const Icon(
        Icons.gavel_rounded,
        color: Color(0xFFC9C4DB),
        size: 42,
      );
}

class _OutlineButton extends StatefulWidget {
  const _OutlineButton({
    required this.onTap,
    required this.hovered,
    required this.compact,
  });

  final VoidCallback onTap;
  final bool hovered;
  final bool compact;

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.97 : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.30),
              width: 1.1,
            ),
            color: Colors.white.withValues(alpha: 0.04),
            boxShadow: [
              if (widget.hovered && kIsWeb)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 7,
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
                  vertical: widget.compact ? 8 : 9,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Explore Judges',
                      style: GoogleFonts.poppins(
                        fontSize: widget.compact ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.homeTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFFC9C4DB),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
