import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/add_to_checkers/ui/find_at_checkers_button.dart';
import 'package:nestprep/features/add_to_checkers/ui/match_as_you_type_button.dart';
import 'package:nestprep/features/add_to_checkers/ui/product_match_panel.dart';
import 'package:nestprep/features/add_to_checkers/ui/product_type_ahead_card.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/basket_compare_copy.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';

import '../../../support/bring_into_view.dart';
import '../../../support/checkers_grocery_harness.dart';
import '../../../support/grocery_list_harness.dart';
import '../../../support/household_fixtures.dart';

/// The grocery list is free and the shops are Premium (subscriptions
/// ADR-0008): a household without Premium sees every shop control, locked,
/// each opening the paywall on the shops; nothing asks a shop anything; and
/// the plain list works as it always has.
void main() {
  const checkers = ProductRetailer.checkers;
  final headline = SubscriptionCopy.headline(PremiumFeature.shops);
  final field = find.byType(TextField);

  final matched = GroceryItem(
    id: 'matched',
    name: 'Full cream milk',
    addedBy: Fixtures.samMemberId,
    addedAt: groceryNow,
    productMatch: pickedMilk,
  );

  Future<CheckersGroceryHarness> open(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    final h = CheckersGroceryHarness();
    await h.pump(
      tester,
      isPremium: false,
      brightness: brightness,
      scale: scale,
    );
    h.list.repository.emitItems([groceryItem('Bread', id: 'bread'), matched]);
    await tester.pumpAndSettle();
    return h;
  }

  void expectNoShopWasAsked(CheckersGroceryHarness h) {
    expect(h.catalogue.searches, isEmpty);
    expect(h.ranker.asked, isEmpty);
    expect(h.matches.target, isNull);
    expect(h.typeAhead.query, isNull);
    expect(h.directory.pushes, isEmpty);
  }

  final findBesideAnItem = find.descendant(
    of: find.byType(FindAtCheckersButton),
    matching: find.byType(InkWell),
  );

  /// Top to bottom, as the screen lays them out.
  final controls = <String, Finder>{
    'the add field’s shop': find.descendant(
      of: find.byType(MatchAsYouTypeButton),
      matching: find.byType(InkWell),
    ),
    'Add to the shop’s cart': find.byKey(
      const ValueKey('add-to-cart-checkers'),
    ),
    'Find at for the unmatched': find.byKey(const ValueKey('find-unmatched')),
    'Compare shops': find.byKey(const ValueKey('compare-shops')),
    'Find at beside an item': findBesideAnItem,
    'changing a match': find.byTooltip(CheckersCopy.changeMatch),
  };

  testWidgets('shows every shop control, each with a lock', (tester) async {
    final h = await open(tester);

    expect(
      find.bySemanticsLabel(CheckersCopy.notMatchingAsYouType),
      findsOneWidget,
    );
    expect(find.text(BasketCompareCopy.entryTitle), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MatchAsYouTypeButton),
        matching: find.bySemanticsLabel(SubscriptionCopy.lockedHint),
      ),
      findsOneWidget,
    );
    for (final key in ['add-to-cart-checkers', 'find-unmatched']) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byIcon(LucideIcons.lock),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('compare-shops')),
        matching: find.byIcon(LucideIcons.lock),
      ),
      findsOneWidget,
    );

    await bringIntoView(tester, findBesideAnItem);
    expect(
      find.descendant(
        of: find.byType(FindAtCheckersButton),
        matching: find.byIcon(LucideIcons.lock),
      ),
      findsOneWidget,
    );
    await bringIntoView(tester, find.byTooltip(CheckersCopy.changeMatch));
    expect(find.textContaining(pickedMilk.name), findsOneWidget);
    expectNoShopWasAsked(h);
  });

  for (final MapEntry(key: name, value: control) in controls.entries) {
    testWidgets('$name opens the paywall on the shops, and asks no shop', (
      tester,
    ) async {
      final h = await open(tester);
      await bringIntoView(tester, control);

      await tester.tap(control);
      await tester.pumpAndSettle();

      expect(find.text(headline), findsOneWidget);
      expect(find.byType(ProductMatchPanel), findsNothing);
      expect(find.text(CheckersCopy.matchAsYouTypeTitle), findsNothing);
      expect(find.text(BasketCompareCopy.title), findsNothing);
      expectNoShopWasAsked(h);
    });
  }

  testWidgets('typing searches no shop and shows no products', (tester) async {
    final h = await open(tester);

    await tester.enterText(field, 'milk');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(ProductTypeAheadCard), findsNothing);
    expectNoShopWasAsked(h);
  });

  testWidgets('adding puts the typed item on the list and looks nothing up', (
    tester,
  ) async {
    final h = await open(tester);

    await tester.enterText(field, 'eggs');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppCopy.groceriesAdd));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(h.list.repository.added.single.name, 'eggs');
    expect(h.list.repository.addedMatched, isEmpty);
    expect(find.text(headline), findsNothing);
    expectNoShopWasAsked(h);
  });

  testWidgets('ticks an item, and clears a match it already had', (
    tester,
  ) async {
    final h = await open(tester);

    await bringIntoView(tester, find.text('Bread'));
    await tester.tap(find.text('Bread'));
    await tester.pumpAndSettle();
    expect(h.list.repository.ticked.single.itemId, 'bread');

    await bringIntoView(tester, find.byTooltip(CheckersCopy.clearMatch));
    await tester.tap(find.byTooltip(CheckersCopy.clearMatch));
    await tester.pumpAndSettle();
    expect(h.list.repository.matchesCleared, ['matched']);
    expect(find.text(headline), findsNothing);
    expectNoShopWasAsked(h);
  });

  testWidgets('fits a phone at 200% text in the dark', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await open(tester, brightness: Brightness.dark, scale: 2);
    expect(tester.takeException(), isNull);

    for (final control in controls.values) {
      await bringIntoView(tester, control);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('a Premium household sees no lock', (tester) async {
    final h = CheckersGroceryHarness();
    await h.pump(tester);
    h.list.repository.emitItems([groceryItem('Bread', id: 'bread'), matched]);
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.lock), findsNothing);
    expect(
      find.bySemanticsLabel(CheckersCopy.matchingAsYouType(checkers)),
      findsOneWidget,
    );
  });
}
