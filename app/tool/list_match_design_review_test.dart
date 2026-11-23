import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_catalogues.dart';
import 'package:nestprep/features/add_to_checkers/state/list_match_controller.dart';
import 'package:nestprep/features/add_to_checkers/state/product_finder.dart';
import 'package:nestprep/features/add_to_checkers/ui/list_match_page.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:provider/provider.dart';

import '../test/support/fake_checkers.dart';
import '../test/support/fake_grocery_repository.dart';
import '../test/support/fake_live_location.dart';
import '../test/support/grocery_list_harness.dart';
import '../test/support/household_fixtures.dart';
import 'review_press.dart';

/// Matching the list one item at a time (groceries ADR-0010): a step with
/// Jev's best selected, and the summary. `flutter test
/// tool/list_match_design_review_test.dart --update-goldens` retakes them.
void main() {
  setUpAll(loadEveryFont);

  for (final (brightness, textScale, isDone, name) in [
    (Brightness.light, 1.0, false, 'list-match-light'),
    (Brightness.dark, 1.0, false, 'list-match-dark'),
    (Brightness.dark, 2.0, false, 'list-match-dark-200-percent-text'),
    (Brightness.light, 1.0, true, 'list-match-summary-light'),
    (Brightness.dark, 1.0, true, 'list-match-summary-dark'),
  ]) {
    testWidgets(name, (tester) async {
      final catalogue = FakeCheckersCatalogue()
        ..products = [
          checkersProduct('Clover Fresh Full Cream Milk 2L', id: 'a'),
          checkersProduct(
            'Darling Fresh Full Cream Milk 2L',
            id: 'b',
            brand: 'Darling',
            cents: 3299,
            oldCents: 3799,
            isOnPromotion: true,
          ),
          checkersProduct(
            'Checkers Housebrand Low Fat Milk 1L',
            id: 'c',
            brand: 'Checkers',
            cents: 1899,
          ),
          checkersProduct(
            'Parmalat Long Life Milk 1L',
            id: 'd',
            brand: 'Parmalat',
            cents: 2199,
            isInStock: false,
          ),
          checkersProduct('Fair Cape Free Range Milk 2L', id: 'e', cents: 4199),
          checkersProduct('First Choice Milk 6 x 1L', id: 'f', cents: 9999),
        ];
      final groceries = FakeGroceryRepository();
      addTearDown(groceries.close);
      final controller = ListMatchController(
        finder: ProductFinder(
          catalogues: RetailerCatalogues({ProductRetailer.checkers: catalogue}),
          placeResolver: CheckersPlaceResolver(
            locationSource: FakeLocationSource(),
            areaPreference: FakeCheckersAreaPreference(),
          ),
          householdId: Fixtures.householdId,
          ranker: FakeProductMatchRanker()..fits = {'a': 0.92},
        ),
        groceryRepository: groceries,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
        shop: ProductRetailer.checkers,
        items: [
          groceryItem(
            'Full cream milk',
            id: 'm',
          ).copyWith(quantity: '2 litres'),
          groceryItem('Bread', id: 'b'),
          groceryItem('Eggs', id: 'e'),
          groceryItem('Dishwashing liquid', id: 'd'),
        ],
      );
      addTearDown(controller.dispose);
      await captureScreen(
        tester,
        name,
        screen: const ListMatchPage(),
        providers: [ChangeNotifierProvider.value(value: controller)],
        brightness: brightness,
        textScale: textScale,
        emit: () async {},
        act: () async {
          if (!isDone) return;
          controller.next();
          await tester.pumpAndSettle();
          controller.next();
          await tester.pumpAndSettle();
          controller.skip();
          await tester.pumpAndSettle();
          controller.remove();
        },
      );
    });
  }
}
