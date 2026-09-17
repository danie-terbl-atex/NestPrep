import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

void main() {
  for (final brightness in bothThemes) {
    group(brightness.name, () {
      testWidgets('every variant renders its label and fires on tap', (
        tester,
      ) async {
        for (final variant in NestButtonVariant.values) {
          var taps = 0;
          await pumpKit(
            tester,
            NestButton(
              label: variant.name,
              variant: variant,
              onPressed: () => taps++,
            ),
            brightness: brightness,
          );
          await tester.tap(find.text(variant.name));
          expect(taps, 1, reason: variant.name);
        }
      });

      testWidgets('loading keeps the label, shows progress and blocks taps', (
        tester,
      ) async {
        var taps = 0;
        await pumpKit(
          tester,
          NestButton(label: 'Save', isLoading: true, onPressed: () => taps++),
          brightness: brightness,
        );
        expect(find.text('Save'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.tap(find.text('Save'), warnIfMissed: false);
        expect(taps, 0);
      });

      testWidgets('a null handler disables the button', (tester) async {
        await pumpKit(
          tester,
          const NestButton(label: 'Off', onPressed: null),
          brightness: brightness,
        );
        expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
        await tester.tap(find.text('Off'), warnIfMissed: false);
        expect(tester.takeException(), isNull);
      });

      testWidgets('meets the touch-target floor at every size', (tester) async {
        for (final size in NestButtonSize.values) {
          await pumpKit(
            tester,
            NestButton(
              label: 'Go',
              size: size,
              isExpanded: false,
              onPressed: () {},
            ),
            brightness: brightness,
          );
          final box = tester.getSize(find.byType(NestButton));
          expect(
            box.height,
            greaterThanOrEqualTo(NestSize.controlSmall),
            reason: size.name,
          );
        }
      });
    });
  }
}
