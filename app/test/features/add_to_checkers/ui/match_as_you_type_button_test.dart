import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/state/retailer_choice_controller.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';

import '../../../support/bring_into_view.dart';
import '../../../support/checkers_grocery_harness.dart';
import '../../../support/fake_checkers.dart';
import '../../../support/grocery_list_harness.dart';
import '../../../support/household_fixtures.dart';

/// The chosen shop's logo at the start of the add field (add-to-checkers
/// ADR-0007, which moves ADR-0006's *Shop at* there), with Checkers and Pick
/// n Pay each behind its own switch (add-to-pnp ADR-0007).
void main() {
  Future<CheckersGroceryHarness> open(
    WidgetTester tester, {
    Set<FeatureFlag> off = const {},
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    final h = CheckersGroceryHarness();
    await h.pump(tester, off: off, brightness: brightness, scale: scale);
    h.list.repository.emitItems([groceryItem('milk')]);
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> openSheet(WidgetTester tester, ProductRetailer shop) async {
    await tester.tap(find.byTooltip(CheckersCopy.matchingAsYouType(shop)));
    await tester.pumpAndSettle();
  }

  testWidgets('the add field starts with Checkers, matching as you type', (
    tester,
  ) async {
    await open(tester);

    expect(
      tester.getSemantics(
        find.bySemanticsLabel(
          CheckersCopy.matchingAsYouType(ProductRetailer.checkers),
        ),
      ),
      matchesSemantics(
        label: CheckersCopy.matchingAsYouType(ProductRetailer.checkers),
        isButton: true,
        hasTapAction: true,
        isSelected: true,
        hasSelectedState: true,
      ),
    );
  });

  testWidgets('the sheet offers both shops, Woolworths soon, and off', (
    tester,
  ) async {
    await open(tester);
    await openSheet(tester, ProductRetailer.checkers);

    expect(
      find.text(CheckersCopy.matchAt(ProductRetailer.checkers)),
      findsOneWidget,
    );
    expect(
      find.text(CheckersCopy.matchAt(ProductRetailer.pickNPay)),
      findsOneWidget,
    );
    expect(
      find.text(CheckersCopy.retailerSoon(ProductRetailer.woolworths)),
      findsOneWidget,
    );
    expect(find.text(CheckersCopy.dontMatchAsYouType), findsOneWidget);
  });

  testWidgets('choosing Pick n Pay makes *Find at* look there', (tester) async {
    final h = await open(tester);
    await openSheet(tester, ProductRetailer.checkers);
    await tester.tap(find.text(CheckersCopy.matchAt(ProductRetailer.pickNPay)));
    await tester.pumpAndSettle();

    expect(h.retailers.chosen, ProductRetailer.pickNPay);
    expect(
      h.retailerPreference.chosen[Fixtures.householdId],
      ProductRetailer.pickNPay,
    );
    await bringIntoView(
      tester,
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.pickNPay)),
    );
    await tester.tap(
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.pickNPay)),
    );
    await tester.pumpAndSettle();
    expect(h.pnpCatalogue.queries, ['milk']);
    expect(h.catalogue.searches, isEmpty);
  });

  testWidgets('with Pick n Pay switched off it shows as coming, and cannot be '
      'chosen', (tester) async {
    final h = await open(tester, off: {FeatureFlag.addToPnp});
    await openSheet(tester, ProductRetailer.checkers);

    await tester.tap(
      find.text(CheckersCopy.retailerSoon(ProductRetailer.pickNPay)),
    );
    await tester.pumpAndSettle();

    expect(h.retailers.chosen, ProductRetailer.checkers);
    expect(h.retailerPreference.chosen, isEmpty);
  });

  testWidgets('turning it off is kept, and the logo says so', (tester) async {
    final h = await open(tester);
    await openSheet(tester, ProductRetailer.checkers);
    await tester.tap(find.text(CheckersCopy.dontMatchAsYouType));
    await tester.pumpAndSettle();

    expect(h.retailers.matchesAsYouType, isFalse);
    expect(h.retailerPreference.matchAsYouType[Fixtures.householdId], isFalse);
    expect(find.byTooltip(CheckersCopy.notMatchingAsYouType), findsOneWidget);
  });

  testWidgets('the item shows the chosen shop\'s logo, and tapping it looks', (
    tester,
  ) async {
    final h = await open(tester);

    await bringIntoView(
      tester,
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.checkers)),
    );
    await tester.tap(
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.checkers)),
    );
    await tester.pumpAndSettle();

    expect(h.catalogue.searches.single.query, 'milk');
  });

  testWidgets('with every shop switched off the field has no logo', (
    tester,
  ) async {
    await open(tester, off: {FeatureFlag.addToCheckers, FeatureFlag.addToPnp});

    expect(
      find.byTooltip(CheckersCopy.matchingAsYouType(ProductRetailer.checkers)),
      findsNothing,
    );
  });

  testWidgets('fits a phone at 200% text in the dark', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await open(tester, brightness: Brightness.dark, scale: 2);
    expect(tester.takeException(), isNull);

    await openSheet(tester, ProductRetailer.checkers);
    expect(tester.takeException(), isNull);
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
        matchAsYouType: preference,
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

    test('matches as you type until it is turned off, and remembers', () async {
      final preference = FakeRetailerPreference()
        ..matchAsYouType[Fixtures.householdId] = false;
      final choice = choiceWith(preference);
      expect(choice.matchesAsYouType, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(choice.matchesAsYouType, isFalse);
    });

    test('choosing a shop to match at turns matching back on', () {
      final preference = FakeRetailerPreference();
      final choice = choiceWith(preference)
        ..setMatchesAsYouType(isOn: false)
        ..matchAsYouTypeAt(ProductRetailer.pickNPay);
      expect(choice.chosen, ProductRetailer.pickNPay);
      expect(choice.matchesAsYouType, isTrue);
      expect(preference.matchAsYouType[Fixtures.householdId], isTrue);
    });
  });
}
