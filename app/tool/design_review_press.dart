import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:provider/provider.dart';

import '../test/support/pump_screen.dart';

/// The screenshot press the design-review files share: the phone it shoots
/// at, the fonts it needs, and the one way a picture is taken. Split out of
/// `design_review_test.dart` when family profiles added its screens, so each
/// set of pictures has a file of its own and none of them copies the shutter.

/// An ordinary phone, shot at 2x so the type is sharp.
const reviewPhone = Size(390, 844);

/// Every font the app ships, read from the bundle's own manifest — the type
/// family *and* the icon font. A test renders in Ahem by default, so without
/// this the screenshots are black boxes where the words and the icons should be,
/// which is the opposite of useful for a design review.
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
Future<void> capturePicture(
  WidgetTester tester,
  String name, {
  required Widget screen,
  required List<ChangeNotifierProvider<Object?>> providers,
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
    brightness: brightness,
    textScale: textScale,
    view: view,
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
