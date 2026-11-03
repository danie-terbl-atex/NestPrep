import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_catalogues.dart';
import 'package:nestprep/features/add_to_checkers/state/product_finder.dart';
import 'package:nestprep/features/add_to_checkers/state/product_match_controller.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/async/async_state.dart';

import '../../../support/checkers_grocery_harness.dart';
import '../../../support/fake_checkers.dart';
import '../../../support/fake_grocery_repository.dart';
import '../../../support/fake_live_location.dart';
import '../../../support/fake_plan_week.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/plan_week_pnp_fixture.dart';

/// Matches at the shop *Shop at* names (add-to-pnp ADR-0007): a search goes
/// to that shop's catalogue only, Jev still ranks it, a pick is stored in
/// that shop's shape, and an item's match is never touched until somebody
/// picks — at either shop.
void main() {
  const code = '000000000000539078_EA';
  late FakeCheckersCatalogue checkers;
  late FakeShopCatalogue pnp;
  late FakeGroceryRepository groceries;
  late FakeProductMatchRanker ranker;
  late ProductMatchController controller;

  setUp(() {
    checkers = FakeCheckersCatalogue()
      ..products = [checkersProduct('Clover Fresh Full Cream Milk 2L')];
    pnp = FakeShopCatalogue()
      ..byQuery['milk'] = [
        pnpProduct('PnP Full Cream Milk 2L', code: '000000000000111111_EA'),
        pnpProduct('Clover Full Cream Milk 2L', code: code),
      ];
    groceries = FakeGroceryRepository();
    ranker = FakeProductMatchRanker();
    controller = ProductMatchController(
      finder: ProductFinder(
        catalogues: RetailerCatalogues(checkers: checkers, pickNPay: pnp),
        placeResolver: CheckersPlaceResolver(
          locationSource: FakeLocationSource(),
          areaPreference: FakeCheckersAreaPreference(),
        ),
        householdId: Fixtures.householdId,
        ranker: ranker,
      ),
      groceryRepository: groceries,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      debounce: Duration.zero,
    );
  });
  tearDown(() => controller.dispose());

  const matchedAtCheckers = GroceryItem(
    id: 'i1',
    name: 'milk',
    addedBy: Fixtures.samMemberId,
    productMatch: pickedMilk,
  );

  Future<void> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await pumpEventQueue();
  }

  test(
    'a search at Pick n Pay asks Pick n Pay only, and Jev ranks it',
    () async {
      ranker.fits = {code: 0.9, '000000000000111111_EA': 0.2};
      controller.lookFor(matchedAtCheckers, at: ProductRetailer.pickNPay);
      await settle();
      expect(pnp.queries, ['milk']);
      expect(checkers.searches, isEmpty);
      expect(controller.target?.shop, ProductRetailer.pickNPay);
      final shown = switch (controller.matches) {
        AsyncData(value: final products) => [for (final p in products) p.id],
        _ => const <String>[],
      };
      expect(shown.first, code);
      expect(controller.bestMatchId, code);
    },
  );

  test('looking at the other shop leaves the item\'s match alone', () async {
    controller.lookFor(matchedAtCheckers, at: ProductRetailer.pickNPay);
    await settle();
    controller.dismiss();
    expect(groceries.matchesSet, isEmpty);
    expect(groceries.matchesCleared, isEmpty);
  });

  test(
    'a pick at Pick n Pay replaces a Checkers match, in PnP\'s shape',
    () async {
      controller.lookFor(matchedAtCheckers, at: ProductRetailer.pickNPay);
      await settle();
      final product = switch (controller.matches) {
        AsyncData(value: final products) => products.last,
        _ => throw StateError('no products'),
      };
      await controller.pick(product);
      final written = groceries.matchesSet.single;
      expect(written.itemId, 'i1');
      expect(written.match.retailer, ProductRetailer.pickNPay);
      expect(written.match.productId, code);
      expect(written.match.articleCode, '000000000000539078');
      expect(written.match.unitOfMeasure, 'EA');
      expect(written.match.pickedBy, Fixtures.samMemberId);
    },
  );
}
