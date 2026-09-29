import 'package:flutter/material.dart';

import 'nest_colors.dart';

/// The type scale, sized for a phone. Two families: headings speak in the
/// wordmark's voice — Nunito, rounded, heavy — and everything read at length
/// is Plus Jakarta Sans (design-system ADR-0003). List titles are light so the
/// content, not the chrome, carries the weight. Colour comes from the ink
/// roles.
@immutable
class NestTextStyles {
  const NestTextStyles({
    required this.display,
    required this.headline,
    required this.title,
    required this.titleLight,
    required this.body,
    required this.bodyStrong,
    required this.bodySecondary,
    required this.label,
    required this.caption,
    required this.button,
  });

  /// Change a family here and everything follows. Both are bundled under
  /// `assets/fonts/` with their OFL licence and declared in `pubspec.yaml`.
  static const fontFamily = 'PlusJakartaSans';

  /// The headings' family: the closest open face to the logo's rounded
  /// wordmark, at the two heavy weights a heading uses.
  static const displayFamily = 'Nunito';

  /// The greeting on a home screen.
  final TextStyle display;

  /// A screen title.
  final TextStyle headline;

  /// A card or section title.
  final TextStyle title;

  /// A big, light list title ("Stand-up").
  final TextStyle titleLight;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle bodySecondary;

  /// Small emphasised text: chips, tile labels, tab labels.
  final TextStyle label;
  final TextStyle caption;
  final TextStyle button;

  factory NestTextStyles.from(NestColors colors) {
    TextStyle style({
      required double size,
      required FontWeight weight,
      required double height,
      Color? color,
      double letterSpacing = 0,
      String family = fontFamily,
    }) => TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color ?? colors.ink,
      letterSpacing: letterSpacing,
    );

    return NestTextStyles(
      display: style(
        size: 32,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.3,
        family: displayFamily,
      ),
      headline: style(
        size: 24,
        weight: FontWeight.w800,
        height: 1.25,
        letterSpacing: -0.2,
        family: displayFamily,
      ),
      title: style(
        size: 18,
        weight: FontWeight.w700,
        height: 1.3,
        family: displayFamily,
      ),
      titleLight: style(
        size: 24,
        weight: FontWeight.w400,
        height: 1.2,
        color: colors.inkSecondary,
      ),
      body: style(size: 16, weight: FontWeight.w400, height: 1.5),
      bodyStrong: style(size: 16, weight: FontWeight.w600, height: 1.5),
      bodySecondary: style(
        size: 15,
        weight: FontWeight.w400,
        height: 1.45,
        color: colors.inkSecondary,
      ),
      label: style(size: 14, weight: FontWeight.w500, height: 1.3),
      caption: style(
        size: 13,
        weight: FontWeight.w400,
        height: 1.35,
        color: colors.inkTertiary,
      ),
      button: style(
        size: 16,
        weight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.1,
      ),
    );
  }
}
