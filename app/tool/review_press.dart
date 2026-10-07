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
  final manifest =
      json.decode(await rootBundle.loadString('FontManifest.json'))
          as List<Object?>;
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

/// Decodes every image on screen for real, then repaints. A test's fake clock
/// never lets an asset image finish decoding, so without this the brand's nest
/// is a blank box in every picture it should be in (design-system ADR-0003).
Future<void> decodeEveryImage(WidgetTester tester) async {
  final images = find.byType(Image);
  if (images.evaluate().isEmpty) return;
  final context = tester.element(images.first);
  final providers = [
    for (final image in tester.widgetList<Image>(images)) image.image,
  ];
  await tester.runAsync(() async {
    for (final provider in providers) {
      await precacheImage(provider, context);
    }
  });
  await tester.pumpAndSettle();
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
  // What to do once the screen has settled and before the shutter — open a
  // sheet, scroll to a part — for a picture of a moment rather than a load.
  Future<void> Function()? act,
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
  if (act != null) {
    await act();
    await tester.pumpAndSettle();
  }
  await decodeEveryImage(tester);

  try {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../design-review/$name.png'),
    );
  } finally {
    debugDisableShadows = true;
  }
}

/// The screen's own vertical list, never a horizontal row of chips inside it.
Finder screenList() => find
    .byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    )
    .last;
