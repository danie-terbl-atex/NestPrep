import 'package:flutter/material.dart';

import 'nest_colors.dart';

/// The type scale (design-system ADR-0020): Mona Sans Display SemiExpanded 600
/// heads, Mona Sans reads.
/// Colour comes from the ink roles.
@immutable
class NestTextStyles {
  const NestTextStyles({
    required this.display,
    required this.headline,
    required this.screenTitle,
    required this.title,
    required this.cardTitle,
    required this.figure,
    required this.figureSmall,
    required this.titleLight,
    required this.body,
    required this.reading,
    required this.bodyStrong,
    required this.bodySecondary,
    required this.label,
    required this.eyebrow,
    required this.caption,
    required this.button,
  });

  static const fontFamily = 'MonaSans';
  static const displayFamily = 'MonaSansDisplay';

  final TextStyle display;
  final TextStyle headline;
  final TextStyle screenTitle;
  final TextStyle title;

  /// The name on a card in a grid or a shelf — a recipe, two to a row: the
  /// heading face, a size under [title] so two lines still fit the card.
  final TextStyle cardTitle;

  /// A number or code somebody reads out or types: sans, tabular.
  final TextStyle figure;
  final TextStyle figureSmall;
  final TextStyle titleLight;
  final TextStyle body;

  /// Text read at arm's length while the hands are busy — a recipe's method
  /// beside the stove: a size up from [body], with more air between lines.
  final TextStyle reading;
  final TextStyle bodyStrong;
  final TextStyle bodySecondary;
  final TextStyle label;

  /// The short spaced label above a heading ("Monday's little win"). The
  /// widget upper-cases it; the words stay sentence case in the copy file.
  final TextStyle eyebrow;
  final TextStyle caption;
  final TextStyle button;

  factory NestTextStyles.from(NestColors colors) {
    TextStyle display({
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
      display: display(size: 40, height: 1.05, tracking: -0.8),
      headline: display(size: 30, height: 1.1, tracking: -0.45),
      screenTitle: display(size: 26, height: 1.15, tracking: -0.3),
      title: display(size: 20, height: 1.2, tracking: -0.1),
      cardTitle: display(size: 17, height: 1.25, tracking: -0.1),
      titleLight: display(
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
      reading: sans(size: 18, weight: FontWeight.w400, height: 1.55),
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
