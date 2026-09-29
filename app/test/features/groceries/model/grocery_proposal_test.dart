import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/grocery_amount.dart';
import 'package:nestprep/features/groceries/model/grocery_need.dart';
import 'package:nestprep/features/groceries/model/grocery_need_reason.dart';
import 'package:nestprep/features/groceries/model/grocery_proposal.dart';
import 'package:nestprep/features/meal_planning/model/ingredient_unit.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/shared/copy/grocery_plan_copy.dart';

const _names = {'ava': 'Ava', 'ben': 'Ben'};

String _reasons(GroceryProposal proposal) =>
    GroceryPlanCopy.reasons(proposal.reasons, nameOf: (id) => _names[id]);

GroceryNeed _dinner(int day, String name, {GroceryAmount? amount}) =>
    GroceryNeed(
      name: name,
      amount: amount,
      reason: MealPlanReason(
        isoWeekday: day,
        slot: MealSlot.dinner,
        mealName: 'Spaghetti',
      ),
    );

GroceryNeed _lunch(String name, int boxes, List<String> children) =>
    GroceryNeed(
      name: name,
      reason: LunchPlanReason(boxes: boxes, childIds: children),
    );

/// Groceries ADR-0002: one line per thing, across meals, lunches and children,
/// saying every reason it is wanted.
void main() {
  test('bread for five lunches and Tuesday dinner is one line', () {
    final proposals = GroceryProposal.merge([
      _dinner(2, 'Bread', amount: const GroceryAmount(2, IngredientUnit.loaf)),
      _lunch('bread ', 3, ['ava']),
      _lunch('BREAD', 2, ['ben']),
    ]);

    expect(proposals, hasLength(1));
    final bread = proposals.single;
    expect(bread.name, 'Bread');
    expect(GroceryPlanCopy.quantity(bread.quantity), '2 loaves');
    expect(_reasons(bread), 'For 5 lunches (Ava, Ben) + Tuesday dinner');
  });

  test('a meal eaten twice needs its ingredients twice', () {
    final mince = GroceryProposal.merge([
      _dinner(
        1,
        'Mince',
        amount: const GroceryAmount(500, IngredientUnit.gram),
      ),
      _dinner(
        4,
        'mince',
        amount: const GroceryAmount(500, IngredientUnit.gram),
      ),
    ]).single;

    expect(GroceryPlanCopy.quantity(mince.quantity), '1 kg');
    expect(_reasons(mince), 'For Monday dinner + Thursday dinner');
  });

  test('many meals are counted rather than listed', () {
    final onions = GroceryProposal.merge([
      for (final day in [5, 1, 3, 2]) _dinner(day, 'Onions'),
    ]).single;
    expect(_reasons(onions), 'For Monday dinner + 3 more meals');
  });

  test('one child’s lunches are theirs by name', () {
    final apples = GroceryProposal.merge([
      _lunch('Apples', 4, ['ava']),
    ]).single;
    expect(_reasons(apples), 'For 4 of Ava’s lunches');
    expect(apples.quantity.isEmpty, isTrue);
  });

  test('a source outside the plans says why in its own words', () {
    final bleach = GroceryProposal.merge([
      const GroceryNeed(name: 'Bleach', reason: LabelledReason('Running low')),
      const GroceryNeed(name: 'bleach', reason: LabelledReason('Running low')),
    ]).single;
    expect(_reasons(bleach), 'Running low');
  });

  test('a nameless or over-long need is never proposed', () {
    expect(
      GroceryProposal.merge([
        _lunch('   ', 1, ['ava']),
        _lunch('x' * (GroceryProposal.keyLimit + 1), 1, ['ava']),
      ]),
      isEmpty,
    );
  });

  test('a very long list of reasons is cut to what the list can store', () {
    final note = GroceryPlanCopy.reasons([
      for (var i = 0; i < 40; i++) LabelledReason('Reason number $i'),
    ], nameOf: (_) => null);
    expect(note.length, lessThanOrEqualTo(200));
    expect(note, endsWith('…'));
  });
}
