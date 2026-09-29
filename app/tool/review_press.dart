import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:provider/single_child_widget.dart';

import '../test/support/pump_screen.dart';

/// The shutter every design-review press shares: one screen at phone size,
/// with the real fonts and the real shadows, written to `design-review/`.
///
/// Every press uses it — the tabs (`design_review_test.dart`), household
/// phase 2's screens (`household_access_review_test.dart`), the kid device
/// (`kid_design_review_test.dart`) and family profiles
/// (`family_design_review_test.dart`) — which is why it is its own file rather
/// than a copy in each (`ENG-02`). A new press imports this; it never writes a
/// second shutter.
const reviewPhone = Size(390, 844);

/// Every font the app ships, read from the bundle's own manifest — the type
/// family *and* the icon font. A test renders in Ahem by default, so without
/// this the screenshots are black boxes where the words and the icons should
/// be, which is the opposite of useful for a design review.
Future<void> loadEveryFont() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<Object?>;
  for (final entry in manifest.cast<Map<String, Object?>>()) {
    final family = entry['family'] as String?;
    final assets = (entry['fonts'] as List<Object?>? ?? const [])
        .cast<Map<String, Object?>>();
    if (family == null || assets.isEmpty) continue;
    final loader = FontLoader(family);
    for (final asset in assets) {
      final path = asset['asset'] as String?;
      if (path != null) loader.addFont(rootBundle.load(path));
    }
    // A family the bundle names but does not carry — cupertino_icons is one —
    // must not take the whole press down with it.
    try {
      await loader.load();
    } on Exception {
      continue;
    }
  }
}

/// Renders one screen at phone size and writes it to `design-review/`.
Future<void> captureScreen(
  WidgetTester tester,
  String name, {
  required Widget screen,
  required List<SingleChildWidget> providers,
  required Future<void> Function() emit,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  HouseholdView? view,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = reviewPhone * 2;
  addTearDown(tester.view.reset);
  // Elevation is part of the look being reviewed; tests normally hide it. It
  // has to go back before the test ends, or the framework's painting-invariant
  // check fails the test it was meant to illustrate.
  debugDisableShadows = false;

  await pumpScreen(
    tester,
    screen,
    providers: providers,
    view: view,
    brightness: brightness,
    textScale: textScale,
  );
  await emit();
  await tester.pumpAndSettle();

  try {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../design-review/$name.png'),
    );
  } finally {
    debugDisableShadows = true;
  }
}
