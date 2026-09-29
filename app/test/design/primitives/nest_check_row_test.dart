import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

void main() {
  for (final brightness in bothThemes) {
    group(brightness.name, () {
      testWidgets('the whole row toggles, and the tick shows it', (
        tester,
      ) async {
        var value = false;
        await pumpKit(
          tester,
          StatefulBuilder(
            builder: (context, setState) => NestCheckRow(
              label: 'I am 18 or older',
              value: value,
              onChanged: (next) => setState(() => value = next),
            ),
          ),
          brightness: brightness,
        );
        expect(find.byIcon(Icons.check), findsNothing);

        await tester.tap(find.text('I am 18 or older'));
        await tester.pumpAndSettle();
        expect(value, isTrue);
        expect(find.byIcon(Icons.check), findsOneWidget);

        await tester.tap(find.text('I am 18 or older'));
        await tester.pumpAndSettle();
        expect(value, isFalse);
      });

      testWidgets('disabled, a tap changes nothing', (tester) async {
        await pumpKit(
          tester,
          const NestCheckRow(label: 'Busy', value: true, onChanged: null),
          brightness: brightness,
        );
        await tester.tap(find.text('Busy'));
        await tester.pump();
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('is at least a touch target tall', (tester) async {
        await pumpKit(
          tester,
          NestCheckRow(label: 'x', value: false, onChanged: (_) {}),
          brightness: brightness,
        );
        expect(
          tester.getSize(find.byType(NestCheckRow)).height,
          greaterThanOrEqualTo(NestSize.controlSmall),
        );
      });
    });
  }
}
