import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

/// `NestBadge`: words and an icon together, never a tone alone (`FE-13`), and
/// one node for a screen reader.
void main() {
  for (final brightness in bothThemes) {
    group(brightness.name, () {
      testWidgets('says its label, and shows its icon', (tester) async {
        await pumpKit(
          tester,
          const NestBadge(
            label: 'Expired',
            tone: NestBadgeTone.danger,
            icon: Icons.error_outline,
          ),
          brightness: brightness,
        );
        expect(find.text('Expired'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.bySemanticsLabel('Expired'), findsOneWidget);
      });

      testWidgets('a long label gives way rather than overflowing', (
        tester,
      ) async {
        await pumpKit(
          tester,
          const SizedBox(
            width: 120,
            child: NestBadge(
              label: 'Expires on Wednesday the thirtieth of April',
              tone: NestBadgeTone.warning,
              icon: Icons.schedule,
            ),
          ),
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
      });
    });
  }
}
