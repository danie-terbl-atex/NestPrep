import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/add_to_checkers/ui/checkers_product_tile.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';

import '../../../support/fake_checkers.dart';
import '../../../support/pump_screen.dart';

/// *Best match* is Jev's ranking, so Twig stands beside it — and only there
/// (design-system ADR-0012): a product the shop merely listed has no Twig.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool isBestMatch,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) => pumpScreen(
    tester,
    Material(
      child: Padding(
        padding: const EdgeInsets.all(NestSpace.lg),
        child: CheckersProductTile(
          product: checkersProduct(
            'Clover Fresh Full Cream Milk 2L',
            isOnPromotion: true,
            oldCents: 4299,
          ),
          isBestMatch: isBestMatch,
          onPick: () {},
        ),
      ),
    ),
    providers: const [],
    brightness: brightness,
    textScale: textScale,
  );

  testWidgets('the best match carries Twig, labelled as the AI\'s pick', (
    tester,
  ) async {
    await pump(tester, isBestMatch: true);
    expect(find.text(CheckersCopy.bestMatch), findsOneWidget);
    expect(find.byType(NestTwig), findsOneWidget);
    expect(find.bySemanticsLabel(AiCopy.twigBestMatch), findsOneWidget);
  });

  testWidgets('a product that was not ranked best has no Twig', (tester) async {
    await pump(tester, isBestMatch: false);
    expect(find.text(CheckersCopy.bestMatch), findsNothing);
    expect(find.byType(NestTwig), findsNothing);
  });

  testWidgets('the best match survives dark at 200% text on a 360-wide phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pump(
      tester,
      isBestMatch: true,
      brightness: Brightness.dark,
      textScale: 2,
    );
    expect(find.byType(NestTwig), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
