import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

/// A shop's logo (add-to-checkers ADR-0006): labelled and at the touch-target
/// floor when it is a control; decoration — silent, no tooltip, no tap, its
/// own size — where the words beside it already name the shop (lunch-box
/// ADR-0024).
void main() {
  const asset = 'assets/retailers/checkers_sixty60.png';
  const label = 'Checkers';

  for (final brightness in bothThemes) {
    group('in ${brightness.name}', () {
      testWidgets('labelled, it is read, has a tooltip and keeps the '
          'touch-target floor', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpKit(
          tester,
          NestLogoTile(asset: asset, label: label, onTap: () {}),
          brightness: brightness,
        );
        expect(find.bySemanticsLabel(label), findsOneWidget);
        expect(
          tester.getSize(find.byType(NestLogoTile)),
          const Size.square(NestSize.touchTarget),
        );
        await tester.longPress(find.byType(NestLogoTile));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text(label), findsOneWidget);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        semantics.dispose();
      });

      testWidgets('decorative, it says nothing, shows no tooltip, takes no '
          'tap and is exactly its size', (tester) async {
        final semantics = tester.ensureSemantics();
        var rowTaps = 0;
        await pumpKit(
          tester,
          NestListRow(
            title: 'Plan this week from $label',
            onTap: () => rowTaps++,
            leading: const NestLogoTile.decorative(
              asset: asset,
              size: NestSize.logoMedium,
            ),
          ),
          brightness: brightness,
        );
        final logo = find.byType(NestLogoTile);
        expect(find.bySemanticsLabel(label), findsNothing);
        expect(tester.getSize(logo), const Size.square(NestSize.logoMedium));
        await tester.tap(logo);
        expect(rowTaps, 1, reason: 'a tap on the logo is a tap on the row');
        await tester.longPress(logo);
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(Tooltip), findsNothing);
        expect(find.text(label), findsNothing);
        semantics.dispose();
      });
    });
  }
}
