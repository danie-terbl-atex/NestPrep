import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

/// `NestQrCode`: dark on light in both themes, so another phone's camera reads
/// it, and one labelled image for a screen reader (household ADR-0012).
void main() {
  for (final brightness in bothThemes) {
    testWidgets('${brightness.name}: one labelled image on Oat', (
      tester,
    ) async {
      await pumpKit(
        tester,
        const NestQrCode(
          data: 'https://app.nestprep.io/invite/ABCD2345',
          semanticLabel: 'QR code to invite Gogo',
        ),
        brightness: brightness,
      );

      expect(find.bySemanticsLabel('QR code to invite Gogo'), findsOneWidget);
      final tile = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(NestQrCode),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((tile.decoration as BoxDecoration).color, NestColors.oat);
      expect(
        tester.getSize(find.byType(CustomPaint).last),
        const Size.square(NestSize.qrCode),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a new link redraws the code', (tester) async {
    Widget code(String data) =>
        NestQrCode(data: data, semanticLabel: 'QR code');
    await pumpKit(tester, code('https://app.nestprep.io/invite/ABCD2345'));
    await pumpKit(tester, code('https://app.nestprep.io/invite/WXYZ6789'));
    expect(
      tester.widget<NestQrCode>(find.byType(NestQrCode)).data,
      endsWith('WXYZ6789'),
    );
    expect(tester.takeException(), isNull);
  });
}
