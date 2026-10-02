import 'package:flutter/material.dart';

import 'nest_colors.dart';

/// The type scale (design-system ADR-0008): Fraunces 600 heads, DM Sans reads.
/// Colour comes from the ink roles.
@immutable
class NestTextStyles {
  const NestTextStyles({
    required this.display,
    required this.headline,
    required this.screenTitle,
    required this.title,
    required this.figure,
    required this.figureSmall,
    required this.titleLight,
    required this.body,
    required this.bodyStrong,
    required this.bodySecondary,
    required this.label,
    required this.eyebrow,
    required this.caption,
    required this.button,
  });

  static const fontFamily = 'DMSans';
  static const displayFamily = 'Fraunces';

  final TextStyle display;
  final TextStyle headline;
  final TextStyle screenTitle;
  final TextStyle title;

  /// A number or code somebody reads out or types: sans, tabular.
  final TextStyle figure;
  final TextStyle figureSmall;
  final TextStyle titleLight;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle bodySecondary;
  final TextStyle label;

  /// The short spaced label above a heading ("Monday's little win"). The
  /// widget upper-cases it; the words stay sentence case in the copy file.
  final TextStyle eyebrow;
  final TextStyle caption;
  final TextStyle button;

  factory NestTextStyles.from(NestColors colors) {
    TextStyle serif({
      required double size,
      required double height,
      required double tracking,
      Color? color,
    }) => TextStyle(
      fontFamily: displayFamily,
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: height,
      letterSpacing: tracking,
      color: color ?? colors.ink,
      // Fraunces keeps its optical-size axis; each style is drawn at its own.
      fontVariations: [FontVariation('opsz', size)],
    );

    TextStyle sans({
      required double size,
      required FontWeight weight,
      required double height,
      Color? color,
      double letterSpacing = 0,
      List<FontFeature>? features,
    }) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color ?? colors.ink,
      letterSpacing: letterSpacing,
      fontFeatures: features,
    );

    const tabular = [FontFeature.tabularFigures()];

    return NestTextStyles(
      display: serif(size: 40, height: 1.05, tracking: -0.8),
      headline: serif(size: 30, height: 1.1, tracking: -0.45),
      screenTitle: serif(size: 26, height: 1.15, tracking: -0.3),
      title: serif(size: 20, height: 1.2, tracking: -0.1),
      titleLight: serif(
        size: 24,
        height: 1.15,
        tracking: -0.2,
        color: colors.inkSecondary,
      ),
      figure: sans(
        size: 32,
        weight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.5,
        features: tabular,
      ),
      figureSmall: sans(
        size: 24,
        weight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        features: tabular,
      ),
      body: sans(size: 16, weight: FontWeight.w400, height: 1.5),
      bodyStrong: sans(size: 16, weight: FontWeight.w600, height: 1.5),
      bodySecondary: sans(
        size: 15,
        weight: FontWeight.w400,
        height: 1.45,
        color: colors.inkSecondary,
      ),
      label: sans(size: 14, weight: FontWeight.w500, height: 1.3),
      eyebrow: sans(
        size: 12,
        weight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 1.3,
        color: colors.inkSecondary,
      ),
      caption: sans(
        size: 13,
        weight: FontWeight.w400,
        height: 1.35,
        color: colors.inkTertiary,
      ),
      button: sans(size: 16, weight: FontWeight.w600, height: 1.25),
    );
  }
}
