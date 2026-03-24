import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/constants/app_constants.dart';
import 'package:winkidoo/core/theme/app_theme.dart';
import 'package:winkidoo/models/judge.dart';

class JudgeSpotlightCard extends StatefulWidget {
  const JudgeSpotlightCard({
    super.key,
    required this.judge,
    required this.judges,
    required this.onExplore,
    this.height,
    this.compact = false,
  });

  final Judge judge;
  final List<Judge> judges;
  final VoidCallback onExplore;
  final double? height;
  final bool compact;

  @override
  State<JudgeSpotlightCard> createState() => _JudgeSpotlightCardState();
}

class _JudgeSpotlightCardState extends State<JudgeSpotlightCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final targetHeight = widget.height ?? (widget.compact ? 176 : 196);
    final orderedJudges = _orderedJudges(widget.judges, widget.judge);
    final topJudge = orderedJudges.first;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: AppTheme.microDuration,
        curve: AppTheme.standardCurve,
        transform: Matrix4.translationValues(0.0, _hovered ? -1.5 : 0.0, 0.0),
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
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppTheme.homeGlowPink.withValues(alpha: 0.05),
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
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Judge Spotlight',
                          style: AppTheme.overline(brightness).copyWith(
                            color: AppTheme.homeTextSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Meet ${_judgeDisplayName(topJudge)}',
                          maxLines: 2,
                          style: GoogleFonts.poppins(
                            fontSize: widget.compact ? 18 : 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppTheme.homeTextPrimary,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          topJudge.tagline ??
                              'Feeling magical. Feeling judgey.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: widget.compact ? 13 : 14,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.homeTextSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
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
                    flex: 8,
                    child: _JudgeFanStack(
                      judges: orderedJudges,
                      compact: widget.compact,
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

List<Judge> _orderedJudges(List<Judge> source, Judge fallback) {
  final unique = <String, Judge>{};
  for (final judge in source) {
    unique[judge.personaId] = judge;
  }
  unique.putIfAbsent(fallback.personaId, () => fallback);

  const orderedPersonas = [
    AppConstants.personaPoeticRomantic,
    AppConstants.personaSassyCupid,
    AppConstants.personaChaosGremlin,
    AppConstants.personaTheEx,
    AppConstants.personaDrLove,
  ];

  return orderedPersonas
      .map((persona) => unique[persona] ?? Judge.placeholder(persona))
      .toList(growable: false);
}

class _JudgeFanStack extends StatelessWidget {
  const _JudgeFanStack({
    required this.judges,
    required this.compact,
  });

  final List<Judge> judges;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: SizedBox(
        width: compact ? 118 : 132,
        height: compact ? 116 : 126,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = judges.length - 1; i >= 0; i--)
              Positioned(
                right: 8 + (i * 8.0),
                bottom: 6 + (i * 2.0),
                child: Transform.rotate(
                  angle: i == 0 ? 0.0 : (-0.12 + (i * 0.055)),
                  child: _JudgePreviewCard(
                    judge: judges[i],
                    compact: compact,
                    highlighted: i == 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JudgePreviewCard extends StatelessWidget {
  const _JudgePreviewCard({
    required this.judge,
    required this.compact,
    required this.highlighted,
  });

  final Judge judge;
  final bool compact;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final w = compact ? 66.0 : 72.0;
    final h = compact ? 88.0 : 96.0;
    final imagePath = _imagePathForJudge(judge);

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? Colors.white.withValues(alpha: 0.60)
              : brightness == Brightness.dark
                  ? AppTheme.glassBorder
                  : const Color(0x33000000),
          width: highlighted ? 1.4 : 1.0,
        ),
        boxShadow: highlighted
            ? AppTheme.elevation2(brightness)
            : AppTheme.elevation1(brightness),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: highlighted
                    ? const [Color(0xFF3A1D58), Color(0xFF1E1038)]
                    : const [Color(0xFF2E1846), Color(0xFF18102C)],
              ),
            ),
          ),
          if (imagePath != null && imagePath.isNotEmpty)
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.60),
                ],
              ),
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Text(
              _judgeDisplayName(judge),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: compact ? 8.5 : 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.homeTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _imagePathForJudge(Judge judge) {
  final fromJudge = judge.avatarAssetPath?.trim();
  if (fromJudge != null && fromJudge.isNotEmpty) {
    return fromJudge;
  }
  switch (judge.personaId) {
    case AppConstants.personaPoeticRomantic:
      return 'assets/images/judge wizard .png';
    case AppConstants.personaSassyCupid:
      return 'assets/images/sassy judge - female.png';
    case AppConstants.personaChaosGremlin:
      return 'assets/images/Chaos Gremlin judge.png';
    case AppConstants.personaTheEx:
      return 'assets/images/The Ex female version.png';
    case AppConstants.personaDrLove:
      return 'assets/images/Dr. Love Female.png';
    default:
      return null;
  }
}

String _judgeDisplayName(Judge judge) {
  if (judge.personaId == AppConstants.personaPoeticRomantic) {
    return 'Romantic Poet';
  }
  return judge.name;
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

class _OutlineButtonState extends State<_OutlineButton>
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
    final brightness = Theme.of(context).brightness;
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
            border: Border.all(
              color: brightness == Brightness.dark
                  ? AppTheme.glassBorder
                  : const Color(0x33000000),
              width: 1,
            ),
            color: brightness == Brightness.dark
                ? AppTheme.glassFill
                : const Color(0x0A000000),
            boxShadow: [
              if (widget.hovered && kIsWeb)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 8,
                ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 14 : 16,
              vertical: widget.compact ? 9 : 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Explore Judges',
                  style: GoogleFonts.poppins(
                    fontSize: widget.compact ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: AppTheme.homeTextPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: brightness == Brightness.dark
                      ? const Color(0xFF9890B0)
                      : const Color(0xFF8B80A0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
