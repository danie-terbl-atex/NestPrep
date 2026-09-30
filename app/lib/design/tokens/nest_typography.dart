import 'package:flutter/material.dart';

import 'nest_colors.dart';

/// The type scale, sized for a phone. Three families (design-system ADR-0004,
/// amending the heading face of ADR-0003): the headings a person reads at a
/// glance — the greeting, a screen's title, a hero line — are Dancing Script;
/// the headings that must be scanned — a card title, a name in a row, a big
/// number or code — stay in the wordmark's rounded Nunito; everything read at
/// length is Plus Jakarta Sans. List titles are light so the content, not the
/// chrome, carries the weight. Colour comes from the ink roles.
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
    required this.caption,
    required this.button,
  });

  /// Change a family here and everything follows. All three are bundled under
  /// `assets/fonts/` with their OFL licence and declared in `pubspec.yaml`.
  static const fontFamily = 'PlusJakartaSans';

  /// The script for glanceable headings, at the one weight they use. Its
  /// x-height is small, so its sizes run a step above the Nunito they replace.
  static const scriptFamily = 'DancingScript';

  /// The scanned headings' family: the closest open face to the logo's rounded
  /// wordmark, at the two heavy weights a heading uses.
  static const displayFamily = 'Nunito';

  /// The greeting on a home screen, or a hero line. Script.
  final TextStyle display;

  /// A heading a screen leads with. Script.
  final TextStyle headline;

  /// The title in a screen's header bar and a section's header. Script.
  final TextStyle screenTitle;

  /// A card, sheet or dialog title, a name in a row. Nunito, because it is
  /// scanned rather than glanced at.
  final TextStyle title;

  /// A big number or a code somebody reads out or types — never script.
  final TextStyle figure;

  /// [figure] a step down, for a number beside other content.
  final TextStyle figureSmall;

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
        size: 36,
        weight: FontWeight.w700,
        height: 1.15,
        family: scriptFamily,
      ),
      headline: style(
        size: 28,
        weight: FontWeight.w700,
        height: 1.2,
        family: scriptFamily,
      ),
      screenTitle: style(
        size: 24,
        weight: FontWeight.w700,
        height: 1.2,
        family: scriptFamily,
      ),
      figure: style(
        size: 32,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.3,
        family: displayFamily,
      ),
      figureSmall: style(
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
