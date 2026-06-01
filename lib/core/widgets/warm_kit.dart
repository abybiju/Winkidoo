// warm_kit.dart — Winkidoo v2 "Holla-warm" shared primitives.
// Orbit field · glossy CTA · warm glass card · italic-serif highlight headline ·
// mono label · gloss avatar · cream chat bubble · persuasion meter · chips.
//
// All primitives are brightness-aware: dark = warm-charcoal glass (the design),
// light = the existing warm light tokens. Colours come only from AppTheme.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:winkidoo/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// ORBIT FIELD — concentric radar rings + warm radial glow background
// ─────────────────────────────────────────────────────────────
class OrbitField extends StatelessWidget {
  const OrbitField({
    super.key,
    required this.child,
    this.cx = 0.5,
    this.cy = 0.16,
    this.intensity = 0.85,
    this.rings = 4,
    this.baseR = 60,
  });

  final Widget child;

  /// Glow/ring anchor as a fraction of the field size (0..1).
  final double cx;
  final double cy;
  final double intensity;
  final int rings;
  final double baseR;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _OrbitPainter(
              cx: cx,
              cy: cy,
              intensity: intensity,
              rings: rings,
              baseR: baseR,
              brightness: brightness,
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.cx,
    required this.cy,
    required this.intensity,
    required this.rings,
    required this.baseR,
    required this.brightness,
  });

  final double cx, cy, intensity, baseR;
  final int rings;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final dark = brightness == Brightness.dark;

    // Base field + warm radial glow.
    final glow = RadialGradient(
      center: Alignment(cx * 2 - 1, (cy - 0.06) * 2 - 1),
      radius: 1.15,
      colors: dark
          ? [
              const Color(0xFFFF7A14).withValues(alpha: 0.30 * intensity),
              const Color(0xFF783400).withValues(alpha: 0.12 * intensity),
              AppTheme.warmBg1,
              AppTheme.warmBg0,
            ]
          : [
              AppTheme.primaryOrange.withValues(alpha: 0.12 * intensity),
              AppTheme.premiumAmber.withValues(alpha: 0.06 * intensity),
              AppTheme.lightBackgroundStart,
              AppTheme.lightBackgroundEnd,
            ],
      stops: const [0.0, 0.26, 0.55, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = glow.createShader(rect));

    // Concentric rings.
    final center = Offset(size.width * cx, size.height * cy);
    for (var i = 0; i < rings; i++) {
      final r = baseR + i * 78;
      final op = math.max((0.16 - i * 0.024) * intensity, 0.02);
      final ringColor = dark
          ? const Color(0xFFFF8C28).withValues(alpha: op)
          : AppTheme.primaryOrange.withValues(alpha: op * 0.8);
      canvas.drawCircle(
        center,
        r.toDouble(),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = ringColor,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.cx != cx ||
      old.cy != cy ||
      old.intensity != intensity ||
      old.rings != rings ||
      old.baseR != baseR ||
      old.brightness != brightness;
}

// ─────────────────────────────────────────────────────────────
// PRESS SCALE — shared tap squish
// ─────────────────────────────────────────────────────────────
class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, required this.onTap, this.scale = 0.96});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GLOSSY BUTTON — gradient body, outer glow, ››› chevron
// ─────────────────────────────────────────────────────────────
class GlossyButton extends StatelessWidget {
  const GlossyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.full = false,
    this.large = true,
    this.icon,
    this.chevron = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool full;
  final bool large;
  final IconData? icon;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final h = large ? 58.0 : 46.0;
    return _PressScale(
      onTap: onTap,
      child: Container(
        height: h,
        width: full ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.glossyButtonGradient,
            stops: [0.0, 0.52, 1.0],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFFCD82).withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.orangeDeep.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: const Color(0xFF2B1500)),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: large ? 16.5 : 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: const Color(0xFF2B1500),
                ),
              ),
            ),
            if (chevron) ...[
              const SizedBox(width: 9),
              const Text('›››',
                  style: TextStyle(
                      color: Color(0xFF2B1500),
                      fontSize: 17,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -2)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WARM CARD — frosted warm glass surface
// ─────────────────────────────────────────────────────────────
class WarmCard extends StatelessWidget {
  const WarmCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.onTap,
    this.glow,
    this.tint,
    this.activeBorder = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  /// Outer warm glow strength (0..1).
  final double? glow;

  /// Optional gradient fill in place of the plain glass.
  final Gradient? tint;
  final bool activeBorder;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final dark = b == Brightness.dark;
    final fill = dark ? AppTheme.warmGlassBg : AppTheme.lightGlassFill;
    final border = activeBorder
        ? AppTheme.primaryOrange.withValues(alpha: 0.5)
        : (dark ? AppTheme.warmLine : AppTheme.lightGlassBorder);

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: tint,
            color: tint == null ? fill : null,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.55 : 0.10),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
              if (glow != null)
                BoxShadow(
                  color: AppTheme.orangeDeep.withValues(alpha: glow!),
                  blurRadius: 50,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) card = _PressScale(onTap: onTap, scale: 0.98, child: card);
    return card;
  }
}

// ─────────────────────────────────────────────────────────────
// HIGHLIGHT HEADLINE — bold display with {italic-serif} highlight words
// ─────────────────────────────────────────────────────────────
class HighlightHeadline extends StatelessWidget {
  const HighlightHeadline(
    this.text, {
    super.key,
    this.size = 38,
    this.textAlign = TextAlign.start,
  });

  /// Wrap highlight words in braces, e.g. 'Hide a {secret}, make them {earn} it'.
  final String text;
  final double size;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final base = AppTheme.display(b).copyWith(
      fontSize: size,
      height: 1.05,
      letterSpacing: -size * 0.03,
    );

    final spans = <InlineSpan>[];
    final re = RegExp(r'\{([^}]*)\}');
    var idx = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > idx) {
        spans.add(TextSpan(text: text.substring(idx, m.start), style: base));
      }
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            m.group(1) ?? '',
            style: AppTheme.serifAccent(b, size: size),
          ),
        ),
      ));
      idx = m.end;
    }
    if (idx < text.length) {
      spans.add(TextSpan(text: text.substring(idx), style: base));
    }

    return RichText(
      textAlign: textAlign,
      text: TextSpan(style: base, children: spans),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MONO LABEL — Space Mono eyebrow
// ─────────────────────────────────────────────────────────────
class MonoLabel extends StatelessWidget {
  const MonoLabel(this.text, {super.key, this.color, this.size = 10.5});
  final String text;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Text(
      text.toUpperCase(),
      style: AppTheme.mono(b, size: size, color: color),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GRADIENT AVATAR — gloss orb with initial
// ─────────────────────────────────────────────────────────────
class GradientAvatar extends StatelessWidget {
  const GradientAvatar({
    super.key,
    required this.initial,
    this.size = 46,
    this.gradient,
    this.glow = false,
    this.ring = false,
  });

  final String initial;
  final double size;
  final List<Color>? gradient;
  final bool glow;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final colors = gradient ?? AppTheme.orbGradient;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: const Alignment(-0.4, -0.6),
          end: const Alignment(0.6, 0.8),
          colors: colors,
        ),
        border: ring ? Border.all(color: AppTheme.warmBg0, width: 2) : null,
        boxShadow: [
          if (glow)
            BoxShadow(
              color: AppTheme.orangeDeep.withValues(alpha: 0.5),
              blurRadius: 22,
              offset: const Offset(0, 8),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Text(
        initial,
        style: GoogleFonts.spaceGrotesk(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF2B1404),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CREAM BUBBLE — holla chat bubble
// ─────────────────────────────────────────────────────────────
class CreamBubble extends StatelessWidget {
  const CreamBubble({
    super.key,
    required this.name,
    required this.text,
    this.time,
    this.initial = '♥',
    this.gradient,
  });

  final String name;
  final String text;
  final String? time;
  final String initial;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientAvatar(initial: initial, size: 34, gradient: gradient),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.creamInk)),
                    if (time != null) ...[
                      const SizedBox(width: 8),
                      Text(time!,
                          style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.creamInk.withValues(alpha: 0.45))),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.creamInk.withValues(alpha: 0.72))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WARM METER — 5-step persuasion meter (Cold → Unlock)
// ─────────────────────────────────────────────────────────────
const List<String> kEmoSteps = [
  'Cold',
  'Curious',
  'Intrigued',
  'Cracking',
  'Unlock'
];

class WarmMeter extends StatelessWidget {
  const WarmMeter({super.key, this.level = 2, this.compact = false});

  /// 0..4
  final int level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final lvl = level.clamp(0, 4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(5, (i) {
            final on = i <= lvl;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == 4 ? 0 : 5),
                height: compact ? 5 : 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: on
                      ? const LinearGradient(colors: AppTheme.orbGradient)
                      : null,
                  color: on
                      ? null
                      : (b == Brightness.dark
                          ? AppTheme.warmInk25
                          : AppTheme.lightTextMuted.withValues(alpha: 0.25)),
                  boxShadow: on
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.6),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MonoLabel(kEmoSteps.first),
              MonoLabel(kEmoSteps[lvl], color: AppTheme.orangeHi),
              MonoLabel(kEmoSteps.last),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WARM CHIP — tinted pill tag
// ─────────────────────────────────────────────────────────────
enum WarmTone { neutral, orange, gold, ok }

class WarmChip extends StatelessWidget {
  const WarmChip({
    super.key,
    required this.label,
    this.tone = WarmTone.neutral,
    this.icon,
  });

  final String label;
  final WarmTone tone;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    late Color bg, fg, bd;
    switch (tone) {
      case WarmTone.orange:
        bg = AppTheme.primaryOrange.withValues(alpha: 0.15);
        fg = AppTheme.orangeHi;
        bd = AppTheme.primaryOrange.withValues(alpha: 0.32);
        break;
      case WarmTone.gold:
        bg = AppTheme.gold.withValues(alpha: 0.15);
        fg = AppTheme.gold;
        bd = AppTheme.gold.withValues(alpha: 0.30);
        break;
      case WarmTone.ok:
        bg = AppTheme.warmOk.withValues(alpha: 0.14);
        fg = AppTheme.warmOk;
        bd = AppTheme.warmOk.withValues(alpha: 0.30);
        break;
      case WarmTone.neutral:
        bg = b == Brightness.dark ? AppTheme.warmGlassBg : AppTheme.lightGlassFill;
        fg = b == Brightness.dark ? AppTheme.warmInk70 : AppTheme.lightTextSecondary;
        bd = b == Brightness.dark ? AppTheme.warmLine : AppTheme.lightGlassBorder;
        break;
    }
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 6)],
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WARM SEG — gradient segmented control
// ─────────────────────────────────────────────────────────────
class WarmSeg extends StatelessWidget {
  const WarmSeg({
    super.key,
    required this.tabs,
    required this.active,
    required this.onTap,
  });

  final List<String> tabs;
  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: b == Brightness.dark ? AppTheme.warmGlassBg : AppTheme.lightGlassFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: b == Brightness.dark ? AppTheme.warmLine : AppTheme.lightGlassBorder),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final on = i == active;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: on
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: AppTheme.glossyButtonGradient,
                          stops: [0.0, 0.52, 1.0])
                      : null,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tabs[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: on
                        ? const Color(0xFF2B1500)
                        : (b == Brightness.dark
                            ? AppTheme.warmInk45
                            : AppTheme.lightTextSecondary),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
