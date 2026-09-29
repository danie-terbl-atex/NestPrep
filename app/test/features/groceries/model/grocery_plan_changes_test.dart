import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_changes.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_diff.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_selection.dart';

import '../../../support/grocery_plan_fixtures.dart';

/// What one *Update the list* writes (groceries ADR-0002): only what the diff
/// offered, only what was ticked, under ids two phones agree on.
void main() {
  final diff = GroceryPlanDiff.of(
    week: planWeek,
    lines: [
      planLine('Bread', quantity: '2 loaves'),
      planLine('Mince', quantity: '1 kg'),
      planLine('Eggs'),
    ],
    items: [
      plannedItem('Mince', quantity: '500 g'),
      plannedItem('Rice'),
      typedItem('Eggs', boughtAt: planNow.subtract(const Duration(days: 1))),
    ],
    staples: const {},
    now: planNow,
  );

  test('keep-in-step writes every add, refresh and removal', () {
    final changes = GroceryPlanChanges.all(diff, existingIds: const {});
    expect([for (final c in changes.creates) c.name], ['Bread']);
    expect(changes.creates.single.quantity, '2 loaves');
    expect(changes.creates.single.week, planWeek);
    expect(changes.refreshes.single.quantity, '1 kg');
    expect(changes.removals, ['plan-$planWeek-rice']);
    // Bought yesterday is a person's call, never keep-in-step's.
    expect(changes.creates.where((c) => c.name == 'Eggs'), isEmpty);
  });

  test('a person’s choice writes only what they left ticked', () {
    final selection = GroceryPlanSelection()
      ..toggleRemoval('plan-$planWeek-rice')
      ..toggleAddAgain('eggs');
    final chosen = selection.chosenFrom(diff);
    final changes = GroceryPlanChanges.chosen(
      diff,
      existingIds: const {},
      addKeys: chosen.addKeys,
      refreshIds: chosen.refreshIds,
      removeIds: chosen.removeIds,
    );
    expect({for (final c in changes.creates) c.name}, {'Bread', 'Eggs'});
    expect(changes.refreshes, hasLength(1));
    expect(changes.removals, isEmpty);
    expect(changes.count, 3);
  });

  test('two phones name the same planned item the same way', () {
    expect(
      GroceryPlanChanges.idFor(planWeek, 'full cream milk'),
      'plan-$planWeek-full-cream-milk',
    );
    expect(
      GroceryPlanChanges.idFor(planWeek, 'crème fraîche'),
      'plan-$planWeek-crème-fraîche',
    );
    expect(GroceryPlanChanges.idFor(planWeek, 'a/b.c'), 'plan-$planWeek-a-b-c');
    expect(GroceryPlanChanges.idFor(planWeek, '!!!'), 'plan-$planWeek-item');
  });

  test('adding again never writes over the bought item’s history', () {
    final again = GroceryPlanDiff.of(
      week: planWeek,
      lines: [planLine('Bread')],
      items: [plannedItem('Bread', boughtAt: planNow)],
      staples: const {},
      now: planNow,
    );
    final changes = GroceryPlanChanges.chosen(
      again,
      existingIds: {'plan-$planWeek-bread', 'plan-$planWeek-bread-2'},
      addKeys: {'bread'},
    );
    expect(changes.creates.single.id, 'plan-$planWeek-bread-3');
  });

  test('nothing ticked writes nothing', () {
    final changes = GroceryPlanChanges.chosen(
      diff,
      existingIds: const {},
      addKeys: const {},
    );
    expect(changes.isEmpty, isTrue);
  });
}
