import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';

import '../../../support/checkers_grocery_harness.dart';
import '../../../support/grocery_list_harness.dart';

/// What a tap on a grocery row does (groceries ADR-0009): with a shop to
/// ask it opens that shop's products and only the circle ticks; with none
/// the whole row still ticks.
void main() {
  Future<CheckersGroceryHarness> list(
    WidgetTester tester, {
    bool isPremium = true,
  }) async {
    final h = CheckersGroceryHarness();
    await h.pump(tester, isPremium: isPremium);
    h.list.repository.emitItems([
      groceryItem('salt', id: 's'),
      groceryItem('milk', id: 'm').copyWith(productMatch: pickedMilk),
    ]);
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('a tap on the row opens the chosen shop\'s products and ticks '
      'nothing; a second tap closes them', (tester) async {
    final h = await list(tester);
    await tap(tester, find.text('salt'));
    expect(h.matches.target?.itemId, 's');
    expect(h.matches.target?.shop, ProductRetailer.checkers);
    expect(h.list.repository.ticked, isEmpty);

    await tap(tester, find.text('salt'));
    expect(h.matches.target, isNull);
    expect(h.list.repository.ticked, isEmpty);
  });

  testWidgets('a row with a product already picked opens too', (tester) async {
    final h = await list(tester);
    await tap(tester, find.text('milk'));
    expect(h.matches.target?.itemId, 'm');
    expect(h.list.repository.ticked, isEmpty);
  });

  testWidgets('only the circle ticks', (tester) async {
    final h = await list(tester);
    await tap(tester, find.byKey(const ValueKey('grocery-tick-s')));
    expect(h.list.repository.ticked.single.itemId, 's');
    expect(h.list.repository.ticked.single.isBought, isTrue);
    expect(h.matches.target, isNull);
  });

  testWidgets('a free household has nothing to open, so the row still ticks', (
    tester,
  ) async {
    final h = await list(tester, isPremium: false);
    await tap(tester, find.text('salt'));
    expect(h.list.repository.ticked.single.itemId, 's');
    expect(h.matches.target, isNull);
  });
}
