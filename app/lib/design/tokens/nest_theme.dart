import 'package:flutter/material.dart';

import 'nest_colors.dart';
import 'nest_member_palette.dart';
import 'nest_shadows.dart';
import 'nest_typography.dart';

/// The one object every kit widget reads. Installed on `ThemeData` as an
/// extension, so `NestTheme.of(context)` follows the active brightness.
/// Retheming the app is a change to this file and the token files it names.
@immutable
class NestTheme extends ThemeExtension<NestTheme> {
  const NestTheme({
    required this.brightness,
    required this.colors,
    required this.text,
    required this.shadows,
    required this.members,
  });

  factory NestTheme.light() => NestTheme(
    brightness: Brightness.light,
    colors: NestColors.light,
    text: NestTextStyles.from(NestColors.light),
    shadows: NestShadows.light,
    members: NestMemberPalette.light,
  );

  factory NestTheme.dark() => NestTheme(
    brightness: Brightness.dark,
    colors: NestColors.dark,
    text: NestTextStyles.from(NestColors.dark),
    shadows: NestShadows.dark,
    members: NestMemberPalette.dark,
  );

  final Brightness brightness;
  final NestColors colors;
  final NestTextStyles text;
  final NestShadows shadows;
  final NestMemberPalette members;

  bool get isDark => brightness == Brightness.dark;

  static NestTheme of(BuildContext context) {
    final theme = Theme.of(context).extension<NestTheme>();
    assert(
      theme != null,
      'NestTheme is missing: build ThemeData with nestThemeData().',
    );
    return theme!;
  }

  @override
  NestTheme copyWith({
    Brightness? brightness,
    NestColors? colors,
    NestTextStyles? text,
    NestShadows? shadows,
    NestMemberPalette? members,
  }) => NestTheme(
    brightness: brightness ?? this.brightness,
    colors: colors ?? this.colors,
    text: text ?? this.text,
    shadows: shadows ?? this.shadows,
    members: members ?? this.members,
  );

  /// Themes switch as a cut, not a blend: the two token sets are discrete.
  @override
  NestTheme lerp(ThemeExtension<NestTheme>? other, double t) =>
      t < 0.5 || other is! NestTheme ? this : other;
}
