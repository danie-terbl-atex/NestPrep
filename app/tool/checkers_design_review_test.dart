import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/add_to_checkers/ui/checkers_product_tile.dart';

import '../test/support/fake_checkers.dart';
import 'review_press.dart';

/// Checkers' product matches under a grocery item, with Jev's *Best match*
/// and Twig beside it (design-system ADR-0012), in both themes and at 200%
/// text. `flutter test tool/checkers_design_review_test.dart
/// --update-goldens` retakes them.
void main() {
  setUpAll(loadEveryFont);

  Widget matches() => Material(
    child: ListView(
      padding: const EdgeInsets.all(NestSpace.lg),
      children: [
        CheckersProductTile(
          product: checkersProduct('Clover Fresh Full Cream Milk 2L'),
          isBestMatch: true,
          onPick: () {},
        ),
        const SizedBox(height: NestSpace.md),
        CheckersProductTile(
          product: checkersProduct(
            'Darling Fresh Full Cream Milk 2L',
            id: 'darling',
            brand: 'Darling',
            cents: 3499,
            oldCents: 3999,
            isOnPromotion: true,
          ),
          onPick: () {},
        ),
      ],
    ),
  );

  for (final (brightness, textScale, name) in [
    (Brightness.light, 1.0, 'checkers-best-match-light'),
    (Brightness.dark, 1.0, 'checkers-best-match-dark'),
    (Brightness.dark, 2.0, 'checkers-best-match-dark-200-percent-text'),
  ]) {
    testWidgets(name, (tester) async {
      await captureScreen(
        tester,
        name,
        screen: matches(),
        providers: const [],
        emit: () async {},
        brightness: brightness,
        textScale: textScale,
      );
    });
  }
}
