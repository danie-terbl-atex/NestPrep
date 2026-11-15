import 'package:flutter/material.dart';

/// How this phone shows NestPrep: as the phone is set, or always day, or
/// always night (design-system ADR-0024).
enum Appearance {
  auto(ThemeMode.system),
  day(ThemeMode.light),
  night(ThemeMode.dark);

  const Appearance(this.themeMode);

  final ThemeMode themeMode;

  static Appearance? fromName(String name) => values.asNameMap()[name];
}
