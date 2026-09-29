import 'package:flutter/material.dart';

/// Every colour the app may paint, by role. The only file with hex literals
/// (`FE-02`); everything else asks `NestTheme.of(context).colors`. Both sets
/// are checked for WCAG AA in `test/design/tokens/nest_contrast_test.dart`.
///
/// The roles are anchored to the logo (design-system ADR-0003): forest green
/// from the wordmark is the one colour that *acts*; the tick's teal says where
/// you are and what is selected; the roof's tomato is warmth, never a label;
/// straw and cream are the page. Dark is the same nest at night — a deep,
/// green-warm charcoal with the greens lifted — not an inversion.
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
    required this.tilePink,
    required this.tileMint,
    required this.tileSky,
    required this.tilePeach,
    required this.scrim,
    required this.skeleton,
  });

  /// The page background behind everything.
  final Color canvas;

  /// The soft straw → cream → leaf wash painted over the canvas.
  final List<Color> canvasWash;

  /// Cards and sheets.
  final Color surface;

  /// A selected row, a tonal button, an icon tile.
  final Color surfaceTint;

  /// The translucent header pills and bottom bar.
  final Color surfaceGlass;
  final Color outline;
  final Color outlineStrong;

  /// Text, from primary to tertiary.
  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;

  /// The brand forest green — every primary action — its pressed shade, and
  /// the text drawn on it.
  final Color accent;
  final Color accentPressed;
  final Color onAccent;

  /// Pale leaf fill for tonal surfaces, and the green used as text on it.
  final Color accentSoft;
  final Color accentInk;

  /// The tick's teal: *state*, not action — the selected day, the tab you
  /// are on, a selected chip, an informational badge. Kept apart from the
  /// accent so a screen's subject and its selection never compete (ADR-0003).
  final Color secondary;
  final Color onSecondary;
  final Color secondarySoft;
  final Color secondaryInk;

  /// The roof's tomato. Warmth only — a caret, a heart — held to 3:1 as a
  /// graphic and never used for words or for a warning (that is `danger`).
  final Color highlight;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color onDanger;

  /// Pastel tints for category icon tiles, drawn from the logo (tomato,
  /// lunchbox leaf, the nest's blue strand, straw) under their old names so no
  /// call site moves. Decorative: never the only signal.
  final Color tilePink;
  final Color tileMint;
  final Color tileSky;
  final Color tilePeach;
  final Color scrim;
  final Color skeleton;

  static const light = NestColors(
    canvas: Color(0xFFF4EDDF),
    canvasWash: [Color(0xFFF2E8D3), Color(0xFFF6F0E4), Color(0xFFE7EFE3)],
    surface: Color(0xFFFFFFFF),
    surfaceTint: Color(0xFFF2ECDF),
    surfaceGlass: Color(0xD9FFFFFF),
    outline: Color(0xFFE3D8C4),
    outlineStrong: Color(0xFFD9CDB7),
    ink: Color(0xFF1C2920),
    inkSecondary: Color(0xFF4F5A52),
    inkTertiary: Color(0xFF5B635C),
    accent: Color(0xFF32533C),
    accentPressed: Color(0xFF26422F),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFE2EEDF),
    accentInk: Color(0xFF2A4A33),
    secondary: Color(0xFF2F6B70),
    onSecondary: Color(0xFFFFFFFF),
    secondarySoft: Color(0xFFDAEDEE),
    secondaryInk: Color(0xFF205A5F),
    highlight: Color(0xFFC24E39),
    success: Color(0xFF1E6B3F),
    successSoft: Color(0xFFE1F2E4),
    warning: Color(0xFF83560B),
    warningSoft: Color(0xFFFAEBCB),
    danger: Color(0xFFB8283A),
    dangerSoft: Color(0xFFFBE4E6),
    onDanger: Color(0xFFFFFFFF),
    tilePink: Color(0xFFFBE3DA),
    tileMint: Color(0xFFE2EFD4),
    tileSky: Color(0xFFDCEAF1),
    tilePeach: Color(0xFFF7E8C8),
    scrim: Color(0x66141A16),
    skeleton: Color(0xFFEDE5D5),
  );

  static const dark = NestColors(
    canvas: Color(0xFF0F1411),
    canvasWash: [Color(0xFF121C16), Color(0xFF171512), Color(0xFF0F1A1C)],
    surface: Color(0xFF212A23),
    surfaceTint: Color(0xFF2A342D),
    surfaceGlass: Color(0xD9212A23),
    outline: Color(0xFF3A443C),
    outlineStrong: Color(0xFF56625A),
    ink: Color(0xFFF5F1E6),
    inkSecondary: Color(0xFFC5C6B8),
    inkTertiary: Color(0xFFA9AC9F),
    accent: Color(0xFF9CCFA7),
    accentPressed: Color(0xFFB2DBBB),
    onAccent: Color(0xFF0F2317),
    accentSoft: Color(0xFF253B2C),
    accentInk: Color(0xFFBCE2C4),
    secondary: Color(0xFF7DC4C9),
    onSecondary: Color(0xFF0B2325),
    secondarySoft: Color(0xFF1D3739),
    secondaryInk: Color(0xFFA9DEE2),
    highlight: Color(0xFFFF907A),
    success: Color(0xFF72D49D),
    successSoft: Color(0xFF173323),
    warning: Color(0xFFF2B84B),
    warningSoft: Color(0xFF3A2D12),
    danger: Color(0xFFFF8088),
    dangerSoft: Color(0xFF3D2024),
    onDanger: Color(0xFF2B0F12),
    tilePink: Color(0xFF40271F),
    tileMint: Color(0xFF24371F),
    tileSky: Color(0xFF1C2F37),
    tilePeach: Color(0xFF3A301C),
    scrim: Color(0x99000000),
    skeleton: Color(0xFF2C352E),
  );
}
