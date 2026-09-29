import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_format.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_options.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_style.dart';
import 'package:nestprep/features/lunch_box/ui/card/offscreen_lunch_card_renderer.dart';

import '../../../support/lunch_card_fixtures.dart';
import '../../../support/lunch_fixtures.dart';

/// The exported image itself (lunch-box ADR-0005): drawn offscreen from a
/// fixture week, checked against a golden, the same bytes every time, and
/// the size each format promises. The design-review press
/// (`tool/lunch_card_design_review_test.dart`) is the same picture in the
/// brand's real fonts; this one uses the test font so it holds on any
/// machine.
void main() {
  const lwazi = LunchCardOptions(childId: LunchFixtures.lwaziId);

  Future<Uint8List> export(
    WidgetTester tester,
    LunchCardOptions options,
  ) async => (await tester.runAsync(
    () => const OffscreenLunchCardRenderer().render(
      content: LunchCardFixtures.content(options),
      options: options,
      inviteHost: 'nestprep.app',
    ),
  ))!;

  Future<ui.Image> decode(WidgetTester tester, Uint8List png) async =>
      (await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(png);
        return (await codec.getNextFrame()).image;
      }))!;

  testWidgets('a story for one child matches its golden', (tester) async {
    final image = await decode(tester, await export(tester, lwazi));
    await expectLater(image, matchesGoldenFile('goldens/lunch_card_story.png'));
  });

  testWidgets('every child on a square, in forest, matches its golden', (
    tester,
  ) async {
    const options = LunchCardOptions(
      childId: null,
      format: LunchCardFormat.post,
      style: LunchCardStyle.forest,
    );
    final image = await decode(tester, await export(tester, options));
    await expectLater(
      image,
      matchesGoldenFile('goldens/lunch_card_family_post.png'),
    );
  });

  testWidgets('the same week exports the same image, byte for byte', (
    tester,
  ) async {
    final first = await export(tester, lwazi);
    final second = await export(tester, lwazi);
    expect(listEquals(first, second), isTrue);
  });

  testWidgets('the phone’s theme and text size never reach the image', (
    tester,
  ) async {
    final plain = await export(tester, lwazi);
    tester.platformDispatcher
      ..platformBrightnessTestValue = ui.Brightness.dark
      ..textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    expect(listEquals(await export(tester, lwazi), plain), isTrue);
  });

  for (final format in LunchCardFormat.values) {
    testWidgets('a ${format.name} is ${format.exportSize} pixels', (
      tester,
    ) async {
      final image = await decode(
        tester,
        await export(tester, lwazi.copyWith(format: format)),
      );
      expect(
        ui.Size(image.width.toDouble(), image.height.toDouble()),
        format.exportSize,
      );
    });
  }
}
