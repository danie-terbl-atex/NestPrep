import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/state/retailer_choice_controller.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';

import '../../../support/checkers_grocery_harness.dart';
import '../../../support/fake_checkers.dart';
import '../../../support/grocery_list_harness.dart';
import '../../../support/household_fixtures.dart';

/// *Shop at* above the grocery list, and the chosen shop's logo beside an
/// unmatched item (add-to-checkers ADR-0006), with Checkers and Pick n Pay
/// each behind its own switch (add-to-pnp ADR-0007).
void main() {
  Future<CheckersGroceryHarness> open(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    final h = CheckersGroceryHarness();
    await h.pump(tester, brightness: brightness, scale: scale);
    h.list.repository.emitItems([groceryItem('milk')]);
    await tester.pumpAndSettle();
    return h;
  }

  testWidgets('offers Checkers and Pick n Pay, Checkers chosen, Woolworths '
      'soon', (tester) async {
    await open(tester);

    expect(
      find.text(CheckersCopy.shopAtRetailer(ProductRetailer.checkers)),
      findsOneWidget,
    );
    for (final shop in [ProductRetailer.checkers, ProductRetailer.pickNPay]) {
      expect(
        find.bySemanticsLabel(CheckersCopy.retailerName(shop)),
        findsOneWidget,
      );
    }
    expect(
      find.text(CheckersCopy.comingSoon(const [ProductRetailer.woolworths])),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(
          CheckersCopy.retailerName(ProductRetailer.checkers),
        ),
      ),
      matchesSemantics(
        label: CheckersCopy.retailerName(ProductRetailer.checkers),
        isButton: true,
        hasTapAction: true,
        isSelected: true,
        hasSelectedState: true,
      ),
    );
  });

  testWidgets('with Pick n Pay switched off it shows as coming, and cannot be '
      'chosen', (tester) async {
    final h = CheckersGroceryHarness();
    await h.pump(tester, off: {FeatureFlag.addToPnp});
    h.list.repository.emitItems([groceryItem('milk')]);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byTooltip(CheckersCopy.retailerSoon(ProductRetailer.pickNPay)),
    );
    await tester.pumpAndSettle();
    expect(h.retailers.chosen, ProductRetailer.checkers);
  });

  testWidgets('choosing Pick n Pay makes *Find at* look there', (tester) async {
    final h = await open(tester);
    await tester.tap(
      find.bySemanticsLabel(
        CheckersCopy.retailerName(ProductRetailer.pickNPay),
      ),
    );
    await tester.pumpAndSettle();
    expect(h.retailers.chosen, ProductRetailer.pickNPay);
    await tester.tap(
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.pickNPay)),
    );
    await tester.pumpAndSettle();
    expect(h.pnpCatalogue.queries, ['milk']);
    expect(h.catalogue.searches, isEmpty);
  });

  testWidgets('a shop that is not connected cannot be chosen', (tester) async {
    final h = await open(tester);

    await tester.tap(
      find.byTooltip(CheckersCopy.retailerSoon(ProductRetailer.woolworths)),
    );
    await tester.pumpAndSettle();

    expect(h.retailers.chosen, ProductRetailer.checkers);
    expect(h.retailerPreference.chosen, isEmpty);
  });

  testWidgets('the item shows the chosen shop\'s logo, and tapping it looks', (
    tester,
  ) async {
    final h = await open(tester);

    await tester.tap(
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.checkers)),
    );
    await tester.pumpAndSettle();

    expect(h.catalogue.searches.single.query, 'milk');
  });

  testWidgets('fits a phone at 200% text in the dark', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await open(tester, brightness: Brightness.dark, scale: 2);

    expect(tester.takeException(), isNull);
    expect(
      find.text(CheckersCopy.shopAtRetailer(ProductRetailer.checkers)),
      findsOneWidget,
    );
  });

  group('the choice on this phone', () {
    RetailerChoiceController choiceWith(
      FakeRetailerPreference preference, {
      List<ProductRetailer> on = const [
        ProductRetailer.checkers,
        ProductRetailer.pickNPay,
      ],
    }) {
      final choice = RetailerChoiceController(
        preference: preference,
        householdId: Fixtures.householdId,
        shopsOn: () => on,
      );
      addTearDown(choice.dispose);
      return choice;
    }

    test('takes a remembered Pick n Pay while its switch is on', () async {
      final preference = FakeRetailerPreference()
        ..chosen[Fixtures.householdId] = ProductRetailer.pickNPay;
      final choice = choiceWith(preference);
      await Future<void>.delayed(Duration.zero);
      expect(choice.chosen, ProductRetailer.pickNPay);
    });

    test('a remembered shop switched off reads as the first one on', () async {
      final preference = FakeRetailerPreference()
        ..chosen[Fixtures.householdId] = ProductRetailer.pickNPay;
      final choice = choiceWith(
        preference,
        on: const [ProductRetailer.checkers],
      );
      await Future<void>.delayed(Duration.zero);
      expect(choice.chosen, ProductRetailer.checkers);
    });

    test('with only Pick n Pay on, Pick n Pay is the shop', () {
      final choice = choiceWith(
        FakeRetailerPreference(),
        on: const [ProductRetailer.pickNPay],
      );
      expect(choice.chosen, ProductRetailer.pickNPay);
    });

    test('never takes a shop that is not connected or switched off', () {
      final preference = FakeRetailerPreference();
      final choice = choiceWith(
        preference,
        on: const [ProductRetailer.checkers],
      );
      choice
        ..choose(ProductRetailer.woolworths)
        ..choose(ProductRetailer.pickNPay);
      expect(choice.chosen, ProductRetailer.checkers);
      expect(preference.chosen, isEmpty);
    });
  });
}
