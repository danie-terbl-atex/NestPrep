import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/plan_week/state/plan_week_retailer.dart';

import '../../../support/fake_plan_week.dart';
import '../../../support/household_fixtures.dart';

/// The shop *Plan my week* plans at (lunch-box ADR-0026), the same for every
/// shop: the brief offers the shops switched on, a choice only when there is
/// more than one, and a run keeps the shop it began at.
void main() {
  final checkers = FakeShopCatalogue();
  final pnp = FakeShopCatalogue();
  final woolworths = FakeShopCatalogue();
  var on = ProductRetailer.values;

  PlanWeekRetailer retailer() {
    final choice = planWeekShopChoice(Fixtures.householdId);
    addTearDown(choice.dispose);
    return PlanWeekRetailer(
      catalogues: planWeekCatalogues(
        checkers,
        pickNPay: pnp,
        woolworths: woolworths,
      ),
      choice: choice,
      shopsOn: () => on,
    );
  }

  setUp(() => on = ProductRetailer.values);

  test('the brief offers every shop switched on, in order', () {
    final shops = retailer();
    expect(shops.choices, ProductRetailer.values);
    expect(shops.canChoose, isTrue);
    expect(shops.shop, ProductRetailer.checkers);
  });

  test('one shop on is no choice, whichever it is', () {
    for (final only in ProductRetailer.values) {
      on = [only];
      final shops = retailer();
      expect(shops.canChoose, isFalse);
      expect(shops.shop, only);
    }
  });

  test('each shop plans from its own catalogue', () {
    final shops = retailer();
    final catalogues = {
      ProductRetailer.checkers: checkers,
      ProductRetailer.pickNPay: pnp,
      ProductRetailer.woolworths: woolworths,
    };
    for (final shop in ProductRetailer.values) {
      shops.choose(shop);
      expect(shops.catalogue, same(catalogues[shop]));
    }
  });

  test('a run keeps the shop it began at until the brief again', () {
    final shops = retailer()..choose(ProductRetailer.woolworths);
    shops.begin();
    shops.choose(ProductRetailer.pickNPay);
    expect(shops.shop, ProductRetailer.woolworths);
    shops.end();
    expect(shops.shop, ProductRetailer.pickNPay);
  });

  test('a chosen shop switched off gives way to the first still on', () {
    final shops = retailer()..choose(ProductRetailer.checkers);
    on = [ProductRetailer.pickNPay, ProductRetailer.woolworths];
    expect(shops.shop, ProductRetailer.pickNPay);
  });

  test('reached with every shop off, it still names a shop to plan at', () {
    on = const [];
    final shops = retailer();
    expect(shops.choices, isEmpty);
    expect(shops.canChoose, isFalse);
    expect(shops.shop, ProductRetailer.values.first);
  });
}
