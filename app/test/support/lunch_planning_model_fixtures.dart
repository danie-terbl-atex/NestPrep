import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_choices.dart';
import 'package:nestprep/features/lunch_box/model/lunch_packed_day.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pantry_entry.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_price.dart';

import 'model_fixtures.dart';

/// Lunch-box's V2 stored models (lunch-box ADR-0006 to ADR-0008), for the
/// every-model round trip — and the grocery line the pantry adds, which is
/// the one that carries a `source`.
List<ModelFixture> lunchPlanningModelFixtures(DateTime at) {
  final pantry = LunchPantryEntry(
    id: 'apple',
    portions: 4,
    updatedBy: 'm1',
    updatedAt: at,
  );
  final packed = LunchPackedDay(
    id: 'm-kid_2026-09-29',
    childId: 'm-kid',
    date: '2026-09-29',
    week: '2026-W40',
    itemIds: const ['apple', 'wrap'],
    by: 'm1',
    at: at,
  );
  final price = LunchPrice(
    id: 'wrap',
    cents: 4200,
    portions: 8,
    updatedBy: 'm1',
    updatedAt: at,
  );
  final budget = LunchBudget(
    id: 'weekly',
    cents: 25000,
    updatedBy: 'm1',
    updatedAt: at,
  );
  const apple = LunchPick(itemId: 'apple', name: 'Apple slices');
  const grapes = LunchPick(itemId: 'grapes', name: 'Grapes');
  final choices = LunchChoices(
    id: 'm-kid_2026-W40',
    childId: 'm-kid',
    week: '2026-W40',
    options: const {
      '2_fruit': [apple, grapes],
    },
    chosen: const {'2_fruit': 'grapes'},
    editedDay: '2',
    chosenKey: '2_fruit',
    updatedBy: 'm1',
    updatedAt: at,
  );
  final fromPantry = GroceryItem(
    id: 'g-pantry',
    name: 'Apple slices',
    quantity: 'for 3 lunch boxes',
    addedBy: 'm1',
    addedAt: at,
    sourceKey: 'apple slices',
    sourceWeek: '2026-W40',
    sourceNote: 'Not in the pantry — 3 lunch boxes need it',
  );
  return [
    ModelFixture(
      label: 'LunchPantryEntry',
      id: pantry.id,
      value: pantry,
      toJson: pantry.toJson,
      fromJson: LunchPantryEntry.fromJson,
      keys: const {'portions', 'updatedBy', 'updatedAt'},
      note:
          'the lunch item is the document id; the rules refuse anything '
          'but whole boxes 0–99.',
    ),
    ModelFixture(
      label: 'LunchPackedDay',
      id: packed.id,
      value: packed,
      toJson: packed.toJson,
      fromJson: LunchPackedDay.fromJson,
      keys: const {'childId', 'date', 'week', 'itemIds', 'by', 'at'},
    ),
    ModelFixture(
      label: 'LunchPrice',
      id: price.id,
      value: price,
      toJson: price.toJson,
      fromJson: LunchPrice.fromJson,
      keys: const {'cents', 'portions', 'currency', 'updatedBy', 'updatedAt'},
      note: 'money is whole cents with its currency written (ENG-20).',
    ),
    ModelFixture(
      label: 'LunchBudget',
      id: budget.id,
      value: budget,
      toJson: budget.toJson,
      fromJson: LunchBudget.fromJson,
      keys: const {'cents', 'currency', 'updatedBy', 'updatedAt'},
    ),
    ModelFixture(
      label: 'LunchChoices',
      id: choices.id,
      value: choices,
      toJson: choices.toJson,
      fromJson: LunchChoices.fromJson,
      keys: const {
        'childId',
        'week',
        'options',
        'chosen',
        'editedDay',
        'chosenKey',
        'updatedBy',
        'updatedAt',
      },
      note:
          'options nest lists of picks as maps, never as models; '
          '`editedDay` and `chosenKey` are what the rules check a write by.',
    ),
    ModelFixture(
      label: 'GroceryItem (from the pantry)',
      id: fromPantry.id,
      value: fromPantry,
      toJson: fromPantry.toJson,
      fromJson: GroceryItem.fromJson,
      keys: const {
        'name',
        'quantity',
        'addedBy',
        'addedAt',
        'boughtAt',
        'boughtBy',
        'sourceKey',
        'sourceWeek',
        'sourceNote',
      },
      note:
          'the pantry writes a planned item, the one provenance groceries '
          'knows (groceries ADR-0002, lunch-box ADR-0006).',
    ),
  ];
}
