import 'package:flutter/material.dart';

/// Every colour the app may paint, by role. The only file with hex literals
/// (`FE-02`); everything else asks `NestTheme.of(context).colors`. Both sets
/// are checked for WCAG AA in `test/design/tokens/nest_contrast_test.dart`.
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

  /// The soft lavender → peach → mint wash painted over the canvas.
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

  /// The brand violet, its pressed shade, and the text drawn on it.
  final Color accent;
  final Color accentPressed;
  final Color onAccent;

  /// Pale violet fill for tonal surfaces, and the violet used as text on it.
  final Color accentSoft;
  final Color accentInk;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color onDanger;

  /// Pastel tints for category icon tiles. Decorative: never the only signal.
  final Color tilePink;
  final Color tileMint;
  final Color tileSky;
  final Color tilePeach;
  final Color scrim;
  final Color skeleton;

  static const light = NestColors(
    canvas: Color(0xFFF7F6FB),
    canvasWash: [Color(0xFFF0EBFB), Color(0xFFFBF3F0), Color(0xFFEDF6F3)],
    surface: Color(0xFFFFFFFF),
    surfaceTint: Color(0xFFF1EEFA),
    surfaceGlass: Color(0xD9FFFFFF),
    outline: Color(0xFFE7E4F0),
    outlineStrong: Color(0xFFCFCBDF),
    ink: Color(0xFF1E1B2E),
    inkSecondary: Color(0xFF5F5C74),
    inkTertiary: Color(0xFF67647D),
    accent: Color(0xFF6C5CE7),
    accentPressed: Color(0xFF5B4BD6),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFECE8FD),
    accentInk: Color(0xFF4A3BC4),
    success: Color(0xFF15734A),
    successSoft: Color(0xFFE3F6EC),
    warning: Color(0xFF8A5A0B),
    warningSoft: Color(0xFFFFF1D6),
    danger: Color(0xFFC42D3A),
    dangerSoft: Color(0xFFFDE7E9),
    onDanger: Color(0xFFFFFFFF),
    tilePink: Color(0xFFFBE4F0),
    tileMint: Color(0xFFDDF5EC),
    tileSky: Color(0xFFE0ECFF),
    tilePeach: Color(0xFFFFE9DF),
    scrim: Color(0x6614121F),
    skeleton: Color(0xFFECEAF3),
  );

  static const dark = NestColors(
    canvas: Color(0xFF13121B),
    canvasWash: [Color(0xFF1B1830), Color(0xFF211A24), Color(0xFF16201D)],
    surface: Color(0xFF1D1C29),
    surfaceTint: Color(0xFF24223A),
    surfaceGlass: Color(0xD91D1C29),
    outline: Color(0xFF2E2C42),
    outlineStrong: Color(0xFF45425E),
    ink: Color(0xFFF3F1FA),
    inkSecondary: Color(0xFFB4B0C9),
    inkTertiary: Color(0xFF9D9AB1),
    accent: Color(0xFFA99CFF),
    accentPressed: Color(0xFFBBB0FF),
    onAccent: Color(0xFF1A1533),
    accentSoft: Color(0xFF2C2848),
    accentInk: Color(0xFFC9C0FF),
    success: Color(0xFF5CD39A),
    successSoft: Color(0xFF16332A),
    warning: Color(0xFFF2B84B),
    warningSoft: Color(0xFF3A2D12),
    danger: Color(0xFFFF7B84),
    dangerSoft: Color(0xFF3B1F24),
    onDanger: Color(0xFF1A1533),
    tilePink: Color(0xFF3A2436),
    tileMint: Color(0xFF1C3A2F),
    tileSky: Color(0xFF1F2A44),
    tilePeach: Color(0xFF3D2A22),
    scrim: Color(0x99000000),
    skeleton: Color(0xFF2A2838),
  );
}
