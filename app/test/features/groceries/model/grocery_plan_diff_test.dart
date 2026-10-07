import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_diff.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_line.dart';

import '../../../support/grocery_plan_fixtures.dart';

GroceryPlanDiff diffOf(
  List<GroceryPlanLine> lines,
  List<GroceryItem> items, {
  Set<String> staples = const {},
}) => GroceryPlanDiff.of(
  week: planWeek,
  lines: lines,
  items: items,
  staples: staples,
  now: planNow,
);

/// Groceries ADR-0002's invariants, pinned on the one class that decides them:
/// the plans add what is missing and take off only what they added — never
/// what a person typed, never what somebody ticked, never another week's.
void main() {
  test('what is missing is offered to add', () {
    final diff = diffOf([planLine('Bread'), planLine('Milk')], const []);
    expect([for (final line in diff.toAdd) line.name], ['Bread', 'Milk']);
    expect(diff.hasChanges, isTrue);
  });

  test('what a person already typed is not added a second time', () {
    final diff = diffOf([planLine('Milk')], [typedItem('  MILK ')]);
    expect(diff.toAdd, isEmpty);
    expect(diff.onList.single.item.name, '  MILK ');
  });

  test('this week’s planned item that is current is simply there', () {
    final diff = diffOf(
      [planLine('Bread', quantity: '2 loaves')],
      [plannedItem('Bread', quantity: '2 loaves')],
    );
    expect(diff.added, hasLength(1));
    expect(diff.hasChanges, isFalse);
  });

  test('a changed amount or reason is offered as a refresh', () {
    final diff = diffOf(
      [planLine('Bread', quantity: '3 loaves', note: 'For 5 lunches')],
      [plannedItem('Bread', quantity: '2 loaves')],
    );
    expect(diff.toRefresh.single.line.quantity, '3 loaves');
    expect(diff.toAdd, isEmpty);
  });

  test('clearing a plan takes away only the unbought items it added', () {
    final diff = diffOf(const [], [
      plannedItem('Bread'),
      plannedItem('Mince', boughtAt: planNow),
      typedItem('Milk'),
      plannedItem('Rice', week: '2026-W39'),
    ]);
    expect([for (final item in diff.toRemove) item.name], ['Bread']);
  });

  test('a typed item is never removed, even with a planned name', () {
    final diff = diffOf(const [], [typedItem('Bread')]);
    expect(diff.toRemove, isEmpty);
  });

  test('a planned item somebody edited is theirs, and stays', () {
    // An edit clears the source fields; to the plans it is typed now.
    final adopted = plannedItem(
      'Bread',
    ).copyWith(sourceKey: null, sourceWeek: null, sourceNote: null);
    final diff = diffOf(const [], [adopted]);
    expect(diff.toRemove, isEmpty);
  });

  test('bought in the last three days is offered unticked, not added', () {
    final diff = diffOf(
      [planLine('Eggs'), planLine('Butter')],
      [
        typedItem('Eggs', boughtAt: planNow.subtract(const Duration(days: 2))),
        typedItem(
          'Butter',
          boughtAt: planNow.subtract(const Duration(days: 4)),
        ),
      ],
    );
    expect(diff.recentlyBought.single.line.name, 'Eggs');
    expect(diff.toAdd.single.name, 'Butter');
  });

  test('this week’s item already bought is bought, however long ago', () {
    final diff = diffOf(
      [planLine('Bread')],
      [
        plannedItem(
          'Bread',
          boughtAt: planNow.subtract(const Duration(days: 6)),
        ),
      ],
    );
    expect(diff.recentlyBought, hasLength(1));
    expect(diff.toAdd, isEmpty);
  });

  test('a tick the server has not timed yet counts as just bought', () {
    final pending = typedItem('Eggs').copyWith(boughtBy: 'm-sam');
    final diff = diffOf([planLine('Eggs')], [pending]);
    expect(diff.recentlyBought, hasLength(1));
  });

  test('a staple is never proposed, and its planned item comes off', () {
    final diff = diffOf(
      [planLine('Salt'), planLine('Rice')],
      [plannedItem('Salt')],
      staples: {'salt'},
    );
    expect(diff.staples.single.name, 'Salt');
    expect(diff.toAdd.single.name, 'Rice');
    expect(diff.toRemove.single.name, 'Salt');
  });

  test('another week’s unbought item counts as on the list', () {
    final diff = diffOf(
      [planLine('Rice')],
      [plannedItem('Rice', week: '2026-W39')],
    );
    expect(diff.onList, hasLength(1));
    expect(diff.toAdd, isEmpty);
    expect(diff.toRemove, isEmpty);
  });

  test('nothing planned and nothing added is empty', () {
    expect(diffOf(const [], [typedItem('Milk')]).isEmpty, isTrue);
  });
}
