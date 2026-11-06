import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/plan_week/state/lunch_shop_choice.dart';

import '../../../support/fake_checkers.dart';
import '../../../support/fake_plan_week.dart';
import '../../../support/household_fixtures.dart';

/// The shop *Plan my week* plans at, kept on this phone (lunch-box
/// ADR-0026): any connected shop, the one chosen here remembered, the
/// family's own shop until then, and only ever a shop switched on.
void main() {
  const all = ProductRetailer.values;
  late FakeLunchShopPreference preference;
  late FakeRetailerPreference family;

  setUp(() {
    preference = FakeLunchShopPreference();
    family = FakeRetailerPreference();
  });

  LunchShopChoice choice() => LunchShopChoice(
    preference: preference,
    familyPreference: family,
    householdId: Fixtures.householdId,
  );

  test('nothing chosen plans at the first shop on, and a choice is kept on '
      'the phone', () async {
    final shop = choice();
    addTearDown(shop.dispose);
    await pumpEventQueue();
    expect(shop.chosen, isNull);
    expect(shop.shopFor(all), ProductRetailer.checkers);
    expect(
      shop.shopFor(const [ProductRetailer.woolworths]),
      ProductRetailer.woolworths,
    );
    shop.choose(ProductRetailer.woolworths);
    expect(shop.shopFor(all), ProductRetailer.woolworths);
    expect(preference.kept[Fixtures.householdId], ProductRetailer.woolworths);
  });

  test('every shop can be chosen', () {
    final shop = choice();
    addTearDown(shop.dispose);
    for (final at in all) {
      shop.choose(at);
      expect(shop.shopFor(all), at);
    }
  });

  test('a remembered shop is taken once read', () async {
    preference.kept[Fixtures.householdId] = ProductRetailer.pickNPay;
    final shop = choice();
    addTearDown(shop.dispose);
    await pumpEventQueue();
    expect(shop.shopFor(all), ProductRetailer.pickNPay);
  });

  test('a tap before the remembered shop is read wins over it', () async {
    preference.kept[Fixtures.householdId] = ProductRetailer.pickNPay;
    final shop = choice()..choose(ProductRetailer.checkers);
    addTearDown(shop.dispose);
    await pumpEventQueue();
    expect(shop.shopFor(all), ProductRetailer.checkers);
    expect(preference.kept[Fixtures.householdId], ProductRetailer.checkers);
  });

  test('a chosen shop switched off plans at the first shop still on', () {
    final shop = choice()..choose(ProductRetailer.pickNPay);
    addTearDown(shop.dispose);
    expect(
      shop.shopFor(const [
        ProductRetailer.checkers,
        ProductRetailer.woolworths,
      ]),
      ProductRetailer.checkers,
    );
    expect(shop.shopFor(all), ProductRetailer.pickNPay);
  });

  test('with every shop switched off there is no shop to plan at', () {
    final shop = choice()..choose(ProductRetailer.checkers);
    addTearDown(shop.dispose);
    expect(shop.shopFor(const []), isNull);
  });

  group('the family’s own shop (Your shops)', () {
    test('leads while nothing is chosen in the lunch builder', () async {
      family.chosen[Fixtures.householdId] = ProductRetailer.woolworths;
      final shop = choice();
      addTearDown(shop.dispose);
      var changes = 0;
      shop.addListener(() => changes++);
      await pumpEventQueue();
      expect(shop.shopFor(all), ProductRetailer.woolworths);
      expect(changes, 1);
      expect(preference.kept, isEmpty);
    });

    test('gives way to a shop the lunch builder remembers', () async {
      family.chosen[Fixtures.householdId] = ProductRetailer.woolworths;
      preference.kept[Fixtures.householdId] = ProductRetailer.pickNPay;
      final shop = choice();
      addTearDown(shop.dispose);
      await pumpEventQueue();
      expect(shop.shopFor(all), ProductRetailer.pickNPay);
    });

    test('leads when the remembered shop is switched off', () async {
      family.chosen[Fixtures.householdId] = ProductRetailer.woolworths;
      preference.kept[Fixtures.householdId] = ProductRetailer.pickNPay;
      final shop = choice();
      addTearDown(shop.dispose);
      await pumpEventQueue();
      expect(
        shop.shopFor(const [
          ProductRetailer.checkers,
          ProductRetailer.woolworths,
        ]),
        ProductRetailer.woolworths,
      );
    });

    test('switched off too, the first shop on leads', () async {
      family.chosen[Fixtures.householdId] = ProductRetailer.woolworths;
      final shop = choice();
      addTearDown(shop.dispose);
      await pumpEventQueue();
      expect(
        shop.shopFor(const [
          ProductRetailer.pickNPay,
          ProductRetailer.checkers,
        ]),
        ProductRetailer.pickNPay,
      );
    });

    test('a tap in the lunch builder wins, and only the lunch builder’s '
        'preference is written', () async {
      family.chosen[Fixtures.householdId] = ProductRetailer.woolworths;
      final shop = choice();
      addTearDown(shop.dispose);
      await pumpEventQueue();
      shop.choose(ProductRetailer.checkers);
      expect(shop.shopFor(all), ProductRetailer.checkers);
      expect(family.chosen[Fixtures.householdId], ProductRetailer.woolworths);
      expect(preference.kept[Fixtures.householdId], ProductRetailer.checkers);
    });
  });

  test('every shop is connected, so every shop can plan lunches '
      '(add-to-woolworths ADR-0001)', () {
    expect(ProductRetailer.values.every((shop) => shop.isConnected), isTrue);
  });
}
