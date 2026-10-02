import 'package:flutter/material.dart';

/// Every colour the app may paint, by role (design-system ADR-0008). The only
/// file with hex literals apart from the member palette and shadows; every
/// pair that ships is proven AA in `test/design/tokens/nest_contrast_test.dart`.
///
/// Ink acts, Guava selects, Basil is the quieter second action, Oat is the
/// page. Guava is 2.45:1 on Oat, so it is only ever a fill with Ink on it;
/// selection drawn as text or a lone glyph uses [secondaryInk].
@immutable
class NestColors {
  const NestColors({
    required this.canvas,
    required this.canvasWash,
    required this.surface,
    required this.surfaceTint,
    required this.surfaceGlass,
    required this.outline,
    required this.outlineStrong,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.accent,
    required this.accentPressed,
    required this.onAccent,
    required this.accentSoft,
    required this.accentInk,
    required this.secondary,
    required this.onSecondary,
    required this.secondarySoft,
    required this.secondaryInk,
    required this.highlight,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.onDanger,
    required this.tileGuava,
    required this.tileBasil,
    required this.tileLilac,
    required this.tileButter,
    required this.scrim,
    required this.skeleton,
    required this.chrome,
    required this.onChrome,
    required this.onChromeMuted,
  });

  final Color canvas;
  final List<Color> canvasWash;
  final Color surface;
  final Color surfaceTint;
  final Color surfaceGlass;
  final Color outline;
  final Color outlineStrong;
  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;

  /// Ink in light, Oat in dark: the primary action and its glyphs.
  final Color accent;
  final Color accentPressed;
  final Color onAccent;

  /// Basil: the tonal second action and text links.
  final Color accentSoft;
  final Color accentInk;

  /// Guava, the selected fill. Never text: see the class note.
  final Color secondary;
  final Color onSecondary;
  final Color secondarySoft;
  final Color secondaryInk;

  /// Guava as decoration, always with Ink over it.
  final Color highlight;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color onDanger;

  /// The brand's four accents as icon-tile fills, each carrying Ink.
  /// Decorative: never the only signal.
  final Color tileGuava;
  final Color tileBasil;
  final Color tileLilac;
  final Color tileButter;
  final Color scrim;
  final Color skeleton;

  /// The floating bar: Ink in light, a lifted Night in dark.
  final Color chrome;
  final Color onChrome;
  final Color onChromeMuted;

  static const oat = Color(0xFFFFF8ED);
  static const inkBrand = Color(0xFF35252E);
  static const guava = Color(0xFFF57B91);
  static const butter = Color(0xFFF3D886);
  static const lilac = Color(0xFFC9BCE8);
  static const basil = Color(0xFF465C48);
  static const night = Color(0xFF211A20);
  static const muted = Color(0xFF75666C);

  static const light = NestColors(
    canvas: oat,
    canvasWash: [oat, oat, oat],
    surface: Color(0xFFF5E9D7),
    surfaceTint: Color(0xFFEFE1CC),
    surfaceGlass: Color(0xF2FFF8ED),
    outline: Color(0xFFD6C2A8),
    outlineStrong: Color(0xFFCDB89E),
    ink: inkBrand,
    inkSecondary: Color(0xFF6E5F65),
    inkTertiary: Color(0xFF6E5F65),
    accent: inkBrand,
    accentPressed: Color(0xFF4A3842),
    onAccent: oat,
    accentSoft: Color(0xFFE4EADC),
    accentInk: basil,
    secondary: guava,
    onSecondary: inkBrand,
    secondarySoft: Color(0xFFFCDDE2),
    secondaryInk: Color(0xFF9E2F47),
    highlight: guava,
    success: Color(0xFF3D6343),
    successSoft: Color(0xFFE2EBDB),
    warning: Color(0xFF7A5200),
    warningSoft: Color(0xFFFAEBC0),
    danger: Color(0xFFB4232F),
    dangerSoft: Color(0xFFFBE1DE),
    onDanger: oat,
    tileGuava: Color(0xFFF9B6C2),
    tileBasil: Color(0xFFC4D4BF),
    tileLilac: lilac,
    tileButter: butter,
    scrim: Color(0x6635252E),
    skeleton: Color(0xFFF1E4D2),
    chrome: inkBrand,
    onChrome: oat,
    onChromeMuted: Color(0xFFD9CBC6),
  );

  static const dark = NestColors(
    canvas: night,
    canvasWash: [night, night, night],
    surface: Color(0xFF2E252C),
    surfaceTint: Color(0xFF3A2F37),
    surfaceGlass: Color(0xF22E252C),
    outline: Color(0xFF54444D),
    outlineStrong: Color(0xFF6A5862),
    ink: oat,
    inkSecondary: Color(0xFFCDBFC4),
    inkTertiary: Color(0xFFB8A9AF),
    accent: oat,
    accentPressed: Color(0xFFEADFD0),
    onAccent: inkBrand,
    accentSoft: Color(0xFF2F3A30),
    accentInk: Color(0xFFB3CDB4),
    secondary: guava,
    onSecondary: inkBrand,
    secondarySoft: Color(0xFF4E2C37),
    secondaryInk: Color(0xFFFFA5B5),
    highlight: guava,
    success: Color(0xFF9ACFA3),
    successSoft: Color(0xFF243327),
    warning: butter,
    warningSoft: Color(0xFF3D3420),
    danger: Color(0xFFFF9B9B),
    dangerSoft: Color(0xFF4A2529),
    onDanger: Color(0xFF2A0E12),
    tileGuava: Color(0xFF5C2F3C),
    tileBasil: Color(0xFF2F4031),
    tileLilac: Color(0xFF40375A),
    tileButter: Color(0xFF4D4227),
    scrim: Color(0x99000000),
    skeleton: Color(0xFF3A2F37),
    chrome: Color(0xFF3A2F37),
    onChrome: oat,
    onChromeMuted: Color(0xFFD9CBC6),
  );
}
