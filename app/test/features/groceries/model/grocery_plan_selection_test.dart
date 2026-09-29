import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_diff.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_selection.dart';

import '../../../support/grocery_plan_fixtures.dart';

GroceryPlanDiff _diff(List<String> names) => GroceryPlanDiff.of(
  week: planWeek,
  lines: [for (final name in names) planLine(name)],
  items: [typedItem('Eggs', boughtAt: planNow)],
  staples: const {},
  now: planNow,
);

/// The sheet is live, so what a person ticked is held as what they changed
/// from the defaults (groceries ADR-0002).
void main() {
  test('new lines start ticked; bought recently starts unticked', () {
    final selection = GroceryPlanSelection();
    final chosen = selection.chosenFrom(_diff(['Bread', 'Eggs']));
    expect(chosen.addKeys, {'bread'});
    expect(selection.hasUntickedIn(_diff(['Bread', 'Eggs'])), isTrue);
  });

  test('a line planned while the sheet is open arrives ticked, and '
      'earlier choices hold', () {
    final selection = GroceryPlanSelection()..toggleAdd('bread');
    final later = _diff(['Bread', 'Milk']);
    expect(selection.chosenFrom(later).addKeys, {'milk'});
  });

  test('tick all includes bought recently; untick all clears everything', () {
    final diff = _diff(['Bread', 'Eggs']);
    final selection = GroceryPlanSelection()..setAll(diff, ticked: true);
    expect(selection.chosenFrom(diff).addKeys, {'bread', 'eggs'});
    expect(selection.hasUntickedIn(diff), isFalse);

    selection.setAll(diff, ticked: false);
    expect(selection.countIn(diff), 0);
  });
}
