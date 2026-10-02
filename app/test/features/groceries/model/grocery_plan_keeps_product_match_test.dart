import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_changes.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_diff.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_line.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/grocery_plan_fixtures.dart';

const _milk = ProductMatch(
  retailer: ProductRetailer.checkers,
  productId: '5d3af63bf434cf8420737dd6',
  articleCode: '10136729EA',
  unitOfMeasure: 'EA',
  name: 'Clover Fresh Full Cream Milk 2L',
  price: Money(3799),
  pickedBy: 'member-sam',
);

GroceryPlanDiff diffOf(List<GroceryPlanLine> lines, List<GroceryItem> items) =>
    GroceryPlanDiff.of(
      week: planWeek,
      lines: lines,
      items: items,
      staples: const {},
      now: planNow,
    );

/// Keeping the list in step with the plans never throws away a product
/// somebody picked (groceries ADR-0002 with the Checkers product matches).
/// Picking does not make a planned item a person's own: the plans still
/// refresh its amount — they just never take it off, and never touch the pick.
void main() {
  test('a planned item with a picked product is never taken off', () {
    final picked = plannedItem('Milk').copyWith(productMatch: _milk);
    final diff = diffOf(const [], [picked, plannedItem('Bread')]);
    expect([for (final item in diff.toRemove) item.name], ['Bread']);
  });

  test('picking keeps it the plans’ item, so its amount still refreshes', () {
    final picked = plannedItem(
      'Milk',
      quantity: '1 bottle',
    ).copyWith(productMatch: _milk);
    final diff = diffOf([planLine('Milk', quantity: '2 bottles')], [picked]);
    expect(diff.toRefresh.single.item.isFromPlans, isTrue);
  });

  test('a refresh writes the amount and the reason, and nothing else', () {
    final picked = plannedItem(
      'Milk',
      quantity: '1 bottle',
    ).copyWith(productMatch: _milk);
    final diff = diffOf([planLine('Milk', quantity: '2 bottles')], [picked]);
    final changes = GroceryPlanChanges.all(diff, existingIds: {picked.id});
    final refresh = changes.refreshes.single;
    expect(refresh.itemId, picked.id);
    expect(refresh.quantity, '2 bottles');
    expect(changes.removals, isEmpty);
    expect(changes.creates, isEmpty);
  });
}
