import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

/// Pumps a kit widget inside the app theme. Every kit test goes through here
/// so each primitive is exercised in both themes.
Future<void> pumpKit(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  bool reduceMotion = false,
}) {
  final nest = brightness == Brightness.dark
      ? NestTheme.dark()
      : NestTheme.light();
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: MaterialApp(
        theme: nestThemeData(nest),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

const bothThemes = [Brightness.light, Brightness.dark];
