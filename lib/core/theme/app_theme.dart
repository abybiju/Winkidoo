import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium 2026 design system for Winkidoo.
/// Cosmic Midnight (dark) + Crystal Dawn (light).
/// Dark cosmic liquid glass with vibrant orange gradient accents.
class AppTheme {
  AppTheme._();

  // ───────────────────────────────────────────────────────────────────────────
  // BRAND COLORS — Cosmic Orange Identity
  // ───────────────────────────────────────────────────────────────────────────
  static const Color primaryOrange = Color(0xFFFF8A1E); // holla warm orange
  static const Color primaryOrangeLight = Color(0xFFFFB44D);
  static const Color primaryOrangeDark = Color(0xFFFF6A00);
  static const Color secondaryViolet = Color(0xFF7C5CFC);
  static const Color secondaryVioletMuted = Color(0xFF5A3EBF);
  static const Color secondaryVioletFaint = Color(0xFF3D2A8A);
  static const Color premiumAmber = Color(0xFFFFCE6A); // warm gold

  // ───────────────────────────────────────────────────────────────────────────
  // WARM-GLASS (v2 "Holla-warm") TOKENS — dark redesign accents
  // ───────────────────────────────────────────────────────────────────────────
  static const Color warmBg0 = Color(0xFF0A0704);
  static const Color warmBg1 = Color(0xFF140D06);
  static const Color warmInk = Color(0xFFFCF5EA);
  static const Color warmInk70 = Color(0xA8FCF5EA); // ~66%
  static const Color warmInk45 = Color(0x6BFCF5EA); // ~42%
  static const Color warmInk25 = Color(0x33FCF5EA); // ~20%
  static const Color orange = Color(0xFFFF8A1E);
  static const Color orangeHi = Color(0xFFFFB44D);
  static const Color orangeDeep = Color(0xFFFF6A00);
  static const Color gold = Color(0xFFFFCE6A);
  static const Color cream = Color(0xFFF6EEE1);
  static const Color creamInk = Color(0xFF1D1409);
  static const Color warmLine = Color(0x1AFFEEDC); // rgba(255,238,220,0.10)
  static const Color warmLineHi = Color(0x2EFFEEDC); // ~0.18
  static const Color warmOk = Color(0xFF8EE3A8);
  static const Color warmGlassBg = Color(0x0BFFF4E6); // warm white ~4.5%

  /// Glossy holla CTA gradient (top→bottom).
  static const List<Color> glossyButtonGradient = [
    Color(0xFFFFC169),
    Color(0xFFFF8E20),
    Color(0xFFFF7100),
  ];

  /// Gradient for gloss avatars / orbs.
  static const List<Color> orbGradient = [orangeHi, orangeDeep];
  static const List<Color> goldGradient = [gold, orange];

  // ───────────────────────────────────────────────────────────────────────────
  // DARK MODE — Cosmic Midnight
  // ───────────────────────────────────────────────────────────────────────────
  static const Color bgTop = Color(0xFF0A0704);
  static const Color bgBottom = Color(0xFF140D06);

  /// Surface layers: frosted glass approach (warm)
  static const Color surface1 = Color(0xFF140D06);
  static const Color surface2 = Color(0xFF1A1109);
  static const Color surface3 = Color(0xFF22160B);
  static const Color surfaceInput = Color(0xFF17100A);

  /// Glass tokens (dark mode)
  static const Color glassFill = Color(0x0AFFFFFF); // white 4%
  static const Color glassFillHover = Color(0x12FFFFFF); // white 7%
  static const Color glassBorder = Color(0x14FFFFFF); // white 8%
  static const Color glassBorderSubtle = Color(0x0AFFFFFF); // white 4%
  static const Color glassBorderOrange = Color(0x26FF8C42); // orange 15%

  /// Card surfaces (dark, warm)
  static const Color darkCardA = Color(0xFF1B1209);
  static const Color darkCardB = Color(0xFF0F0A05);

  // ───────────────────────────────────────────────────────────────────────────
  // LIGHT MODE — Crystal Dawn
  // ───────────────────────────────────────────────────────────────────────────
  static const Color lightBackgroundStart = Color(0xFFFAF9FE);
  static const Color lightBackgroundEnd = Color(0xFFF2EDFA);

  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFEFCFF);

  /// Light card tones
  static const Color lightCardA = Color(0xFFFBF7FF);
  static const Color lightCardB = Color(0xFFF6F1FF);

  /// Glass tokens (light mode)
  static const Color lightGlassFill = Color(0xBFFFFFFF); // white 75%
  static const Color lightGlassBorder = Color(0x26785AB4); // violet 15%

  /// Light nav / top bar
  static const Color lightTopBar = Color(0xFFF5F2FD);
  static const Color lightNavBg = Color(0xFFF0ECF8);
  static const Color lightPillBg = Color(0xFFFFF0D6);
  static const Color lightPillBorder = Color(0xFFE8D5B0);
  static const Color lightBadgeBg = Color(0xFFE06B20);

  // ───────────────────────────────────────────────────────────────────────────
  // TEXT COLORS
  // ───────────────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFCF5EA); // warm cream ink
  static const Color textSecondary = Color(0xA8FCF5EA); // ~66%
  static const Color textMuted = Color(0x6BFCF5EA); // ~42%
  static const Color textOrangeAccent = Color(0xFFFFB44D);

  static const Color lightTextPrimary = Color(0xFF1A1028);
  static const Color lightTextSecondary = Color(0xFF6B5A80);
  static const Color lightTextMuted = Color(0xFF9888AE);

  // ───────────────────────────────────────────────────────────────────────────
  // ACCENT GRADIENTS
  // ───────────────────────────────────────────────────────────────────────────
  /// Battle/primary CTA gradient (holla orange)
  static const Color battleGradientA = Color(0xFFFFB44D);
  static const Color battleGradientB = Color(0xFFFF6A00);

  /// CTA gradient (orange capsule — Holla-inspired)
  static const Color ctaOrangeA = Color(0xFFFF8E20);
  static const Color ctaOrangeB = Color(0xFFFF7100);
  static const Color ctaInnerGlow = Color(0x66FFC88C); // warm highlight
  static const Color ctaOuterGlow = Color(0x80FF7100); // shadow glow

  /// Gold CTA gradient (premium)
  static const Color ctaGoldA = Color(0xFFFFD666);
  static const Color ctaGoldB = Color(0xFFFFCE6A);

  /// Vault gradient (cards, warm)
  static const Color vaultGradientA = Color(0xFF1B1209);
  static const Color vaultGradientB = Color(0xFF0F0A05);

  /// Spotlight gradient (warm)
  static const Color spotlightGradientA = Color(0xFF1A1109);
  static const Color spotlightGradientB = Color(0xFF22160B);

  // ───────────────────────────────────────────────────────────────────────────
  // HOME SCREEN PALETTE
  // ───────────────────────────────────────────────────────────────────────────
  static const Color homeBgTop = Color(0xFF0A0704);
  static const Color homeBgBottom = Color(0xFF140D06);
  static const Color homeGlowOrange = Color(0xFFFF8A1E);
  static const Color homeGlowPink = Color(0xFFFF6A00); // warm secondary glow
  static const Color homeTextPrimary = Color(0xFFFCF5EA);
  static const Color homeTextSecondary = Color(0xA8FCF5EA);
  static const Color homeSurfaceMuted = Color(0x26171009);
  static const Color homeSurfaceCard = Color(0x331A1109);
  static const Color homeDivider = Color(0x1AFFEEDC); // warm divider
  static const Color homeCtaNavyA = Color(0xFF1B1209);
  static const Color homeCtaNavyB = Color(0xFF0F0A05);

  // ───────────────────────────────────────────────────────────────────────────
  // VAULT SCREEN PALETTE
  // ───────────────────────────────────────────────────────────────────────────
  static const Color vaultStatusLinked = Color(0xFF8EE3A8);
  static const Color vaultStatusPending = Color(0xFFFFCE6A);
  static const Color vaultCardUrgent = Color(0xFFFFB44D);
  static const Color vaultCardOwned = Color(0xFFFFCE6A);
  static const Color vaultDramaSurfaceA = Color(0xFF1B1209);
  static const Color vaultDramaSurfaceB = Color(0xFF0A0704);
  static const Color vaultDramaVignette = Color(0x990A0704);
  static const Color vaultCtaPrimaryA = Color(0xFFFFB44D);
  static const Color vaultCtaPrimaryB = Color(0xFFFF6A00);
  static const Color vaultCtaInnerGlow = Color(0x4DFFC88C);
  static const Color vaultCtaSecondaryStroke = Color(0x4DFFE3C0);
  static const Color vaultCtaSecondaryFill = Color(0x0BFFF4E6);
  static const Color vaultHeroCharacterOverlay = Color(0x33FF8A1E);

  // ───────────────────────────────────────────────────────────────────────────
  // NAVIGATION PALETTE
  // ───────────────────────────────────────────────────────────────────────────
  static const Color footerBase = Color(0xFF140D06);
  static const Color footerStroke = Color(0x1AFFEEDC);
  static const Color footerActive = Color(0xFFFF8A1E);
  static const Color footerInactive = Color(0xFF6B5E4D);
  static const Color footerCenter = Color(0xFFFF8A1E);
  static const Color footerCenterOn = Color(0xFF2B1500);

  // ───────────────────────────────────────────────────────────────────────────
  // SEMANTIC
  // ───────────────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF4DE8A5);
  static const Color warning = Color(0xFFFFD166);
  static const Color info = Color(0xFF7C9DFC);

  // ───────────────────────────────────────────────────────────────────────────
  // LEGACY ALIASES (backward compat — point to new values)
  // ───────────────────────────────────────────────────────────────────────────
  static const Color primaryPink = primaryOrange;
  static const Color plum = secondaryViolet;
  static const Color premiumGold = premiumAmber;
  static const Color primary = primaryOrange;
  static const Color secondary = secondaryViolet;
  static const Color accent = premiumAmber;
  static const Color backgroundStart = bgTop;
  static const Color backgroundEnd = bgBottom;
  static const Color surface = surface1;
  static const Color sparkColor = Color(0xFFFFB44D);
  static const Color orbitalLine = Color(0x33FF8A1E); // warm orbit ring
  static const Color winsSurface = Color(0x331A1109);
  static const Color ctaBattleA = battleGradientA;
  static const Color ctaBattleB = battleGradientB;

  // Legacy light aliases
  static const Color lightSunTop = lightBackgroundStart;
  static const Color lightSunBottom = lightBackgroundEnd;

  // ───────────────────────────────────────────────────────────────────────────
  // TYPOGRAPHY SCALE
  // ───────────────────────────────────────────────────────────────────────────

  /// Display — hero numbers, large stats (Hanken Grotesque, tight)
  static TextStyle display(Brightness brightness) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.1,
        color: brightness == Brightness.dark ? textPrimary : lightTextPrimary,
      );

  /// Stat numbers — XP, levels, streak counts (Hanken Grotesque)
  static TextStyle statNumber(Brightness brightness) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.5,
        color: brightness == Brightness.dark ? textPrimary : lightTextPrimary,
      );

  static TextStyle heading1(Brightness brightness) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.12,
        letterSpacing: -0.7,
        color: brightness == Brightness.dark ? textPrimary : lightTextPrimary,
      );

  static TextStyle heading2(Brightness brightness) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.4,
        color: brightness == Brightness.dark ? textPrimary : lightTextPrimary,
      );

  static TextStyle heading3(Brightness brightness) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.2,
        color: brightness == Brightness.dark ? textPrimary : lightTextPrimary,
      );

  /// Subheading — section labels, pill text
  static TextStyle subheading(Brightness brightness) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 0.0,
        color: brightness == Brightness.dark ? textPrimary : lightTextPrimary,
      );

  /// Mono label — Space Mono uppercase tracked (eyebrows, timers, counts).
  static TextStyle mono(Brightness brightness,
          {double size = 10.5, Color? color}) =>
      GoogleFonts.spaceMono(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: color ??
            (brightness == Brightness.dark ? textMuted : lightTextMuted),
      );

  /// Serif accent — Instrument Serif italic, the "highlight word" treatment.
  static TextStyle serifAccent(Brightness brightness,
          {double size = 38, Color? color}) =>
      GoogleFonts.instrumentSerif(
        fontSize: size,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: color ?? orangeHi,
      );

  static TextStyle bodyLarge(Brightness brightness) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: brightness == Brightness.dark ? textPrimary : lightTextPrimary,
      );

  static TextStyle bodyMedium(Brightness brightness) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color:
            brightness == Brightness.dark ? textSecondary : lightTextSecondary,
      );

  static TextStyle caption(Brightness brightness) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: brightness == Brightness.dark ? textMuted : lightTextMuted,
      );

  static TextStyle overline(Brightness brightness) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 1.0,
        color: brightness == Brightness.dark ? textMuted : lightTextMuted,
      );

  static TextStyle labelBold(Brightness brightness) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: brightness == Brightness.dark ? textPrimary : lightTextPrimary,
      );

  // ───────────────────────────────────────────────────────────────────────────
  // ELEVATION SYSTEM
  // ───────────────────────────────────────────────────────────────────────────

  /// Level 0: flat — no shadow
  static List<BoxShadow> elevation0() => const [];

  /// Level 1: subtle card shadow
  static List<BoxShadow> elevation1(Brightness brightness) => [
        BoxShadow(
          color: brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.40)
              : const Color(0x18000000),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Level 2: prominent card shadow with violet accent tint
  static List<BoxShadow> elevation2(Brightness brightness) => [
        BoxShadow(
          color: brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.45)
              : const Color(0x20000000),
          blurRadius: 36,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: brightness == Brightness.dark
              ? primaryOrange.withValues(alpha: 0.10)
              : secondaryViolet.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Level 3: premium glow — multi-layer with warm orange tint
  static List<BoxShadow> elevation3(Brightness brightness) => [
        BoxShadow(
          color: brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.50)
              : const Color(0x26000000),
          blurRadius: 48,
          offset: const Offset(0, 24),
        ),
        BoxShadow(
          color: brightness == Brightness.dark
              ? primaryOrange.withValues(alpha: 0.16)
              : primaryOrange.withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: brightness == Brightness.dark
              ? primaryOrange.withValues(alpha: 0.10)
              : secondaryViolet.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // Legacy elevation aliases
  static List<BoxShadow> premiumElevation(Brightness brightness) =>
      elevation3(brightness);

  static List<BoxShadow> toyCardShadow(Brightness brightness) =>
      elevation2(brightness);

  static List<BoxShadow> toyPillShadow(Brightness brightness) =>
      elevation1(brightness);

  static BoxShadow shadowLayer1(Brightness brightness) =>
      elevation3(brightness)[0];

  static BoxShadow shadowLayer2(Brightness brightness) =>
      elevation3(brightness)[1];

  static BoxShadow shadowLayer3(Brightness brightness) =>
      elevation3(brightness)[2];

  // ───────────────────────────────────────────────────────────────────────────
  // STANDARD GLOWS
  // ───────────────────────────────────────────────────────────────────────────

  static BoxShadow get orangeGlow => BoxShadow(
        color: primaryOrange.withValues(alpha: 0.30),
        blurRadius: 24,
        spreadRadius: 1,
      );

  static BoxShadow get amberGlow => BoxShadow(
        color: premiumAmber.withValues(alpha: 0.35),
        blurRadius: 26,
        spreadRadius: 1,
      );

  static BoxShadow get violetGlow => BoxShadow(
        color: secondaryViolet.withValues(alpha: 0.25),
        blurRadius: 22,
        spreadRadius: 1,
      );

  // Legacy glow aliases
  static BoxShadow get pinkGlow => orangeGlow;
  static BoxShadow get goldGlow => amberGlow;

  // ───────────────────────────────────────────────────────────────────────────
  // GLASSMORPHISM
  // ───────────────────────────────────────────────────────────────────────────

  /// Standard glass card decoration
  static BoxDecoration glassDecoration(Brightness brightness,
      {double borderRadius = 24}) {
    return BoxDecoration(
      color: brightness == Brightness.dark ? glassFill : lightGlassFill,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color:
            brightness == Brightness.dark ? glassBorder : lightGlassBorder,
      ),
      boxShadow: elevation1(brightness),
    );
  }

  /// Orange-tinted glass decoration for active/highlighted panels
  static BoxDecoration glassDecorationOrange(Brightness brightness,
      {double borderRadius = 24}) {
    return BoxDecoration(
      color: brightness == Brightness.dark
          ? const Color(0x0FFF8C42) // orange 6%
          : const Color(0x0FFF8C42),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: glassBorderOrange,
        width: 1.2,
      ),
      boxShadow: [
        ...elevation1(brightness),
        BoxShadow(
          color: primaryOrange.withValues(alpha: 0.08),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Prominent glass decoration for overlays & bottom sheets
  static BoxDecoration frostedOverlay(Brightness brightness,
      {double borderRadius = 28}) {
    return BoxDecoration(
      color: brightness == Brightness.dark
          ? const Color(0x1AFFFFFF)
          : const Color(0xCCFFFFFF),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: brightness == Brightness.dark
            ? glassBorder
            : lightGlassBorder,
        width: 1.2,
      ),
      boxShadow: elevation2(brightness),
    );
  }

  /// Sigma for backdrop blur
  static double get glassBlurSigma => 20.0;
  static double get frostedBlurSigma => 28.0;

  // ───────────────────────────────────────────────────────────────────────────
  // ANIMATION TOKENS
  // ───────────────────────────────────────────────────────────────────────────

  /// Standard micro-animation duration
  static const Duration microDuration = Duration(milliseconds: 200);

  /// Standard transition duration
  static const Duration transitionDuration = Duration(milliseconds: 350);

  /// Page transition duration
  static const Duration pageTransitionDuration = Duration(milliseconds: 400);

  /// Shimmer sweep duration
  static const Duration shimmerDuration = Duration(milliseconds: 1800);

  /// Stagger delay for list animations
  static const Duration staggerDelay = Duration(milliseconds: 60);

  /// Glow pulse cycle duration
  static const Duration glowPulseDuration = Duration(milliseconds: 2400);

  /// Spring curve for press animations
  static const Curve springCurve = Curves.easeOutBack;

  /// Standard ease for transitions
  static const Curve standardCurve = Curves.easeOutCubic;

  // ───────────────────────────────────────────────────────────────────────────
  // BORDER RADIUS TOKENS
  // ───────────────────────────────────────────────────────────────────────────
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 20.0;
  static const double radiusLarge = 28.0;
  static const double radiusXL = 36.0;
  static const double radiusPill = 999.0;

  // ───────────────────────────────────────────────────────────────────────────
  // BRIGHTNESS-AWARE HELPERS (preserved API)
  // ───────────────────────────────────────────────────────────────────────────

  static Color topBarBg(Brightness brightness) =>
      brightness == Brightness.dark ? surface2 : lightTopBar;

  static Color cardGradientA(Brightness brightness) =>
      brightness == Brightness.dark ? darkCardA : lightCardA;

  static Color cardGradientB(Brightness brightness) =>
      brightness == Brightness.dark ? darkCardB : lightCardB;

  static Color pillBg(Brightness brightness) =>
      brightness == Brightness.dark ? premiumAmber : lightPillBg;

  static Color pillBorder(Brightness brightness) =>
      brightness == Brightness.dark
          ? secondaryViolet.withValues(alpha: 0.4)
          : lightPillBorder;

  static Color navBg(Brightness brightness) =>
      brightness == Brightness.dark ? footerBase : lightNavBg;

  static Color navActive(Brightness brightness) =>
      brightness == Brightness.dark ? footerActive : const Color(0xFFD06A1A);

  static Color navInactive(Brightness brightness) =>
      brightness == Brightness.dark ? footerInactive : const Color(0xFF8A7A9B);

  static Color navTextStrong(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF5C3800);

  static Color badgeBg(Brightness brightness) =>
      brightness == Brightness.dark ? primaryOrange : lightBadgeBg;

  static Color premiumBorder30(Brightness brightness) =>
      brightness == Brightness.dark
          ? warmLine
          : const Color(0x33785AB4);

  // ───────────────────────────────────────────────────────────────────────────
  // GRADIENT HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  static List<Color> gradientColors(Brightness brightness) =>
      brightness == Brightness.dark
          ? const [backgroundStart, backgroundEnd]
          : const [lightBackgroundStart, lightBackgroundEnd];

  /// 3-stop cosmic background gradient
  static List<Color> cosmicBackgroundGradient(Brightness brightness) =>
      brightness == Brightness.dark
          ? const [bgTop, Color(0xFF0F0A05), bgBottom]
          : const [lightBackgroundStart, lightBackgroundEnd];

  static List<Color> homeBackgroundGradient(Brightness brightness) =>
      brightness == Brightness.dark
          ? const [homeBgTop, homeBgBottom]
          : const [lightBackgroundStart, lightBackgroundEnd];

  /// Orange CTA gradient (Holla-style capsule)
  static List<Color> orangeCtaGradient(Brightness brightness) =>
      brightness == Brightness.dark
          ? const [ctaOrangeA, ctaOrangeB]
          : const [Color(0xFFFF9A42), Color(0xFFFF7A2E)];

  /// Violet accent gradient for secondary elements
  static List<Color> violetAccentGradient(Brightness brightness) =>
      brightness == Brightness.dark
          ? const [secondaryViolet, secondaryVioletMuted]
          : const [Color(0xFF8A6CFF), Color(0xFF6B4EE0)];

  static List<Color> battleGradient(Brightness brightness) =>
      brightness == Brightness.dark
          ? const [homeSurfaceCard, homeSurfaceMuted]
          : const [Color(0xFFF5F1FC), Color(0xFFEDE8F5)];

  static List<Color> vaultGradient(Brightness brightness) =>
      brightness == Brightness.dark
          ? const [homeSurfaceCard, homeSurfaceMuted]
          : const [Color(0xFFF5F1FC), Color(0xFFEDE8F5)];

  static List<Color> vaultHeroGradient(Brightness brightness) =>
      brightness == Brightness.dark
          ? const [vaultDramaSurfaceA, vaultDramaSurfaceB]
          : const [Color(0xFFF8F0FF), Color(0xFFF2EAFC)];

  static List<Color> vaultHeroGlow(Brightness brightness) =>
      brightness == Brightness.dark
          ? [
              primaryOrange.withValues(alpha: 0.14),
              secondaryViolet.withValues(alpha: 0.08),
              Colors.transparent,
            ]
          : [
              primaryOrange.withValues(alpha: 0.10),
              secondaryViolet.withValues(alpha: 0.06),
              Colors.transparent,
            ];

  static List<Color> spotlightGradient(Brightness brightness) =>
      brightness == Brightness.dark
          ? const [homeSurfaceCard, homeSurfaceMuted]
          : const [Color(0xFFF5F1FC), Color(0xFFEDE8F5)];

  static List<Color> goldCtaGradient(Brightness brightness) =>
      brightness == Brightness.dark
          ? const [ctaGoldA, ctaGoldB]
          : const [Color(0xFFFFE98F), Color(0xFFF6CD70)];

  static List<Color> homeCtaNavyGradient(Brightness brightness) =>
      brightness == Brightness.dark
          ? const [homeCtaNavyA, homeCtaNavyB]
          : const [Color(0xFF2D375B), Color(0xFF212A47)];

  // ───────────────────────────────────────────────────────────────────────────
  // THEME DATA
  // ───────────────────────────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryOrange,
        secondary: secondaryViolet,
        surface: surface1,
        error: error,
        onPrimary: Colors.white,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      scaffoldBackgroundColor: bgTop,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: textPrimary,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          height: 1.5,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          height: 1.45,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          elevation: 0,
          textStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(
              color: secondaryViolet.withValues(alpha: 0.20), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: primaryOrange, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: surface2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: glassBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        backgroundColor: surface3,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryOrange,
        secondary: secondaryViolet,
        surface: lightSurface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: lightBackgroundStart,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: lightTextPrimary,
        ),
        iconTheme: const IconThemeData(color: lightTextPrimary),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: lightTextPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: lightTextPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          height: 1.5,
          color: lightTextPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          height: 1.45,
          color: lightTextSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          elevation: 0,
          textStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide(
              color: lightTextMuted.withValues(alpha: 0.30), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: primaryOrange, width: 1.5),
        ),
        labelStyle: const TextStyle(color: lightTextSecondary),
        hintStyle: const TextStyle(color: lightTextMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: lightGlassBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
    );
  }
}
