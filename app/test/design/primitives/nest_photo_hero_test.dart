import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

/// The top of a page that opens on a photo: a fixed shape so nothing moves
/// when it arrives (`FE-18`), and a labelled way back on it in both themes.
void main() {
  for (final brightness in bothThemes) {
    testWidgets('holds its shape and offers the way back — $brightness', (
      tester,
    ) async {
      var backs = 0;
      await pumpKit(
        tester,
        SizedBox(
          width: 360,
          child: NestPhotoHero(
            photo: const ColoredBox(color: Colors.brown),
            backLabel: 'Back',
            onBack: () => backs++,
            semanticsLabel: 'A photo of bobotie',
          ),
        ),
        brightness: brightness,
      );

      expect(tester.getSize(find.byType(NestPhotoHero)).height, 270);
      expect(find.bySemanticsLabel('A photo of bobotie'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back'));
      expect(backs, 1);
    });
  }

  testWidgets('a decorative photo says nothing of its own', (tester) async {
    await pumpKit(
      tester,
      SizedBox(
        width: 360,
        child: NestPhotoHero(
          photo: const Text('picture'),
          backLabel: 'Back',
          onBack: () {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('picture'), findsNothing);
  });
}
