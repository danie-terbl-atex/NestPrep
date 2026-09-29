import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/data/firestore_lunch_budget_repository.dart';
import 'package:nestprep/features/lunch_box/data/firestore_lunch_choices_repository.dart';
import 'package:nestprep/features/lunch_box/data/firestore_lunch_pantry_repository.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_choices.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pantry_entry.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_price.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/shared/money/money.dart';

/// Lunch-box's V2 limits and names, written in Dart and again in the rules
/// partials (lunch-box ADR-0006 to ADR-0008) — the vault lesson on a
/// contract between two languages: change one side and this fails, rather
/// than a household meeting a refusal the app did not expect.
void main() {
  String partial(String name) =>
      File('../rules/firestore/household/$name.rules').readAsStringSync();
  final pantry = partial('lunch_pantry');
  final budget = partial('lunch_budget');
  final picks = partial('lunch_kid_picks');

  test('the collections are the ones the rules guard', () {
    expect(
      pantry,
      contains('match /${FirestoreLunchPantryRepository.pantryPath}/'),
    );
    expect(
      pantry,
      contains('match /${FirestoreLunchPantryRepository.packedPath}/'),
    );
    expect(
      budget,
      contains('match /${FirestoreLunchBudgetRepository.pricesPath}/'),
    );
    expect(
      budget,
      contains('match /${FirestoreLunchBudgetRepository.budgetPath}/'),
    );
    expect(budget, contains("budgetId == '${LunchBudget.weekly}'"));
    expect(
      picks,
      contains('match /${FirestoreLunchChoicesRepository.choicesPath}/'),
    );
  });

  test('a pantry holds whole boxes up to the same limit, and a packed box at '
      'most one of each compartment', () {
    expect(
      pantry,
      contains('data.portions <= ${LunchPantryEntry.portionLimit}'),
    );
    expect(
      pantry,
      contains('data.itemIds.size() <= ${LunchSlot.values.length}'),
    );
  });

  test('prices and budgets keep the same bounds, in the same currency', () {
    expect(budget, contains('data.cents <= ${LunchPrice.centsLimit}'));
    expect(budget, contains('data.portions <= ${LunchPrice.portionLimit}'));
    expect(budget, contains('data.cents >= ${LunchBudget.minimumCents}'));
    expect(budget, contains('data.cents <= ${LunchBudget.centsLimit}'));
    expect(budget, contains("data.currency == '${Currency.zar.code}'"));
  });

  test('a child is offered two or three', () {
    expect(picks, contains('options.size() >= ${LunchChoices.fewestOptions}'));
    expect(picks, contains('options.size() <= ${LunchChoices.mostOptions}'));
  });

  test('the slot key the rules accept is every key a plan holds, and no '
      'other', () {
    final pattern = RegExp(
      RegExp(
        r"isLunchSlotKey\(key\) \{\s+return key is string && key\.matches\('([^']+)'\)",
      ).firstMatch(picks)!.group(1)!,
    );
    for (final key in LunchPlan.allSlotKeys) {
      expect(pattern.hasMatch(key), isTrue, reason: key);
    }
    for (final key in ['0_main', '6_main', '1_lunch', '1_Main', '1_main2']) {
      expect(pattern.hasMatch(key), isFalse, reason: key);
    }
  });
}
