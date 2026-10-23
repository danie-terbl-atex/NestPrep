import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/plan_week/state/lunch_shop_choice.dart';

import '../../../support/fake_plan_week.dart';
import '../../../support/household_fixtures.dart';

/// The shop *Plan my week* plans at, kept on this phone (lunch-box
/// ADR-0026): Checkers until chosen, remembered, and Checkers again while
/// Pick n Pay is switched off.
void main() {
  late FakeLunchShopPreference preference;

  setUp(() => preference = FakeLunchShopPreference());

  LunchShopChoice choice() => LunchShopChoice(
    preference: preference,
    householdId: Fixtures.householdId,
  );

  test('starts at Checkers, and keeps a choice on the phone', () async {
    final shop = choice();
    addTearDown(shop.dispose);
    expect(shop.chosen, ProductRetailer.checkers);
    shop.choose(ProductRetailer.pickNPay);
    expect(shop.chosen, ProductRetailer.pickNPay);
    expect(preference.kept[Fixtures.householdId], ProductRetailer.pickNPay);
  });

  test('a remembered shop is taken once read', () async {
    preference.kept[Fixtures.householdId] = ProductRetailer.pickNPay;
    final shop = choice();
    addTearDown(shop.dispose);
    await pumpEventQueue();
    expect(shop.chosen, ProductRetailer.pickNPay);
  });

  test('a tap before the remembered shop is read wins over it', () async {
    preference.kept[Fixtures.householdId] = ProductRetailer.pickNPay;
    final shop = choice()..choose(ProductRetailer.checkers);
    addTearDown(shop.dispose);
    await pumpEventQueue();
    expect(shop.chosen, ProductRetailer.checkers);
    expect(preference.kept[Fixtures.householdId], ProductRetailer.checkers);
  });

  test('Pick n Pay switched off plans at Checkers', () {
    final shop = choice()..choose(ProductRetailer.pickNPay);
    addTearDown(shop.dispose);
    expect(shop.shopFor(isPnpOn: false), ProductRetailer.checkers);
    expect(shop.shopFor(isPnpOn: true), ProductRetailer.pickNPay);
  });

  test('a shop that cannot plan lunches is never chosen', () async {
    preference.kept[Fixtures.householdId] = ProductRetailer.woolworths;
    final shop = choice();
    addTearDown(shop.dispose);
    await pumpEventQueue();
    shop.choose(ProductRetailer.woolworths);
    expect(shop.chosen, ProductRetailer.checkers);
  });

  test('Checkers and Pick n Pay are connected; Woolworths is not yet '
      '(add-to-pnp ADR-0007)', () {
    expect(
      [
        for (final shop in ProductRetailer.values)
          if (shop.isConnected) shop,
      ],
      [ProductRetailer.checkers, ProductRetailer.pickNPay],
    );
  });
}
