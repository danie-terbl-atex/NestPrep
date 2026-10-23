import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/ui/product_match_line.dart';
import 'package:nestprep/features/add_to_checkers/ui/retailer_logo.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/checkers_grocery_harness.dart';
import '../../../support/grocery_list_harness.dart';
import '../../../support/household_fixtures.dart';

/// A grocery list matched at two shops (add-to-pnp ADR-0007): one cart
/// action per shop with items matched there, each sending only its own
/// shop's items — Pick n Pay with their packs — and one quiet line for the
/// items nobody matched.
void main() {
  const pnpMatch = ProductMatch(
    retailer: ProductRetailer.pickNPay,
    productId: '000000000000539078_EA',
    articleCode: '000000000000539078',
    unitOfMeasure: 'EA',
    name: 'Clover Full Cream Yoghurt 1kg',
    price: Money(4599),
    pickedBy: Fixtures.samMemberId,
  );

  Future<CheckersGroceryHarness> mixedList(
    WidgetTester tester, {
    Set<FeatureFlag> off = const {},
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    final h = CheckersGroceryHarness();
    await h.pump(tester, off: off, brightness: brightness, scale: scale);
    h.list.repository.emitItems([
      groceryItem('milk', id: 'm').copyWith(productMatch: pickedMilk),
      groceryItem('more milk', id: 'm2').copyWith(productMatch: pickedMilk),
      groceryItem(
        'yoghurt',
        id: 'y',
      ).copyWith(productMatch: pnpMatch, quantity: PlanWeekCopy.packs(3)),
      groceryItem('salt', id: 's'),
    ]);
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('one action per shop, counted, and the unmatched line', (
    tester,
  ) async {
    await mixedList(tester);
    expect(
      find.text(CheckersCopy.addCountTo(ProductRetailer.checkers, 2)),
      findsOneWidget,
    );
    expect(
      find.text(CheckersCopy.addCountTo(ProductRetailer.pickNPay, 1)),
      findsOneWidget,
    );
    expect(find.text(CheckersCopy.notMatched(1)), findsOneWidget);
  });

  testWidgets('Pick n Pay gets only its own items, with their packs', (
    tester,
  ) async {
    final h = await mixedList(tester);
    await tapKey(tester, 'add-to-cart-pickNPay');
    final pushed = h.pnpDirectory.pushes.single;
    expect(pushed.itemIds, ['y']);
    expect(pushed.quantities, {'y': 3});
    expect(h.directory.pushes, isEmpty);
  });

  testWidgets('Checkers gets only its own items', (tester) async {
    final h = await mixedList(tester);
    await tapKey(tester, 'add-to-cart-checkers');
    expect(h.directory.pushes.single.itemIds, ['m', 'm2']);
    expect(h.pnpDirectory.pushes, isEmpty);
  });

  testWidgets('a shop switched off has no action', (tester) async {
    await mixedList(tester, off: {FeatureFlag.addToPnp});
    expect(find.byKey(const ValueKey('add-to-cart-pickNPay')), findsNothing);
    expect(find.byKey(const ValueKey('add-to-cart-checkers')), findsOneWidget);
  });

  testWidgets('*Find at* on the unmatched line opens the first unmatched '
      'item at the chosen shop', (tester) async {
    final h = await mixedList(tester);
    await tapKey(tester, 'find-unmatched');
    expect(h.matches.target?.itemId, 's');
    expect(h.matches.target?.shop, ProductRetailer.checkers);
  });

  testWidgets('every match line shows its shop', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mixedList(tester);
    Finder logoOnLine(ProductRetailer shop) => find.descendant(
      of: find.byType(ProductMatchLine),
      matching: find.byWidgetPredicate(
        (widget) => widget is RetailerLogo && widget.retailer == shop,
      ),
    );
    expect(logoOnLine(ProductRetailer.pickNPay), findsOneWidget);
    expect(logoOnLine(ProductRetailer.checkers), findsNWidgets(2));
  });

  testWidgets('a mixed list fits a 360-wide phone at 200% text in the dark', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mixedList(tester, brightness: Brightness.dark, scale: 2);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
