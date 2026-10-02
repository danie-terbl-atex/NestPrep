import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/state/retailer_choice_controller.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';

import '../../../support/checkers_grocery_harness.dart';
import '../../../support/fake_checkers.dart';
import '../../../support/grocery_list_harness.dart';
import '../../../support/household_fixtures.dart';

/// *Shop at* above the grocery list, and the chosen shop's logo beside an
/// unmatched item (add-to-checkers ADR-0006).
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

  testWidgets('offers every shop, with Checkers chosen and the rest soon', (
    tester,
  ) async {
    await open(tester);

    expect(
      find.text(CheckersCopy.shopAtRetailer(ProductRetailer.checkers)),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        CheckersCopy.retailerName(ProductRetailer.checkers),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        CheckersCopy.retailerSoon(ProductRetailer.pickNPay),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        CheckersCopy.retailerSoon(ProductRetailer.woolworths),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        CheckersCopy.comingSoon(const [
          ProductRetailer.pickNPay,
          ProductRetailer.woolworths,
        ]),
      ),
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
    test('ignores a remembered shop that is not connected', () async {
      final preference = FakeRetailerPreference()
        ..chosen[Fixtures.householdId] = ProductRetailer.pickNPay;
      final choice = RetailerChoiceController(
        preference: preference,
        householdId: Fixtures.householdId,
      );
      addTearDown(choice.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(choice.chosen, ProductRetailer.checkers);
    });

    test('keeps a connected choice per household', () async {
      final preference = FakeRetailerPreference();
      final choice = RetailerChoiceController(
        preference: preference,
        householdId: Fixtures.householdId,
      );
      addTearDown(choice.dispose);

      choice.choose(ProductRetailer.woolworths);
      expect(choice.chosen, ProductRetailer.checkers);
      expect(preference.chosen, isEmpty);
    });
  });
}
