import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_line.dart';
import 'package:nestprep/features/groceries/model/grocery_proposal.dart';
import 'package:nestprep/features/groceries/model/grocery_quantity.dart';
import 'package:nestprep/shared/text/normalised_name.dart';

import 'household_fixtures.dart';

/// The week every groceries phase 2 test plans: Monday 28 September 2026.
const planWeek = '2026-W40';

/// The clock those tests read: Tuesday 29 September 2026, noon UTC.
final planNow = DateTime.utc(2026, 9, 29, 12);

/// A proposal as the sheet would word it.
GroceryPlanLine planLine(String name, {String? quantity, String? note}) =>
    GroceryPlanLine(
      proposal: GroceryProposal(
        key: normalisedName(name),
        name: name,
        quantity: GroceryQuantity.sum(const []),
        reasons: const [],
      ),
      quantity: quantity,
      note: note ?? 'For Tuesday dinner',
    );

/// Something a person typed.
GroceryItem typedItem(
  String name, {
  String? id,
  DateTime? boughtAt,
  String addedBy = Fixtures.samMemberId,
}) => GroceryItem(
  id: id ?? 'typed-${normalisedName(name)}',
  name: name,
  addedBy: addedBy,
  addedAt: planNow,
  boughtAt: boughtAt,
  boughtBy: boughtAt == null ? null : Fixtures.samMemberId,
);

/// Something the plans put on the list.
GroceryItem plannedItem(
  String name, {
  String? id,
  String week = planWeek,
  String? quantity,
  String note = 'For Tuesday dinner',
  DateTime? boughtAt,
}) => GroceryItem(
  id: id ?? 'plan-$week-${normalisedName(name)}',
  name: name,
  quantity: quantity,
  addedBy: Fixtures.samMemberId,
  addedAt: planNow,
  boughtAt: boughtAt,
  boughtBy: boughtAt == null ? null : Fixtures.samMemberId,
  sourceKey: normalisedName(name),
  sourceWeek: week,
  sourceNote: note,
);
