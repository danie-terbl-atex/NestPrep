import 'package:flutter/foundation.dart';

import '../../meal_planning/model/week_plan.dart';

/// Why something is wanted — shown beside it, and stored on the item as the
/// sentence it was shown as (groceries ADR-0002).
///
/// Sealed so everything that words a reason says something for each kind; a
/// source outside the plans (home-care's stock tracker, groceries ADR-0004)
/// says why in its own words through [LabelledReason].
sealed class GroceryNeedReason {
  const GroceryNeedReason();
}

/// A meal in one slot of the week's plan.
final class MealPlanReason extends GroceryNeedReason {
  const MealPlanReason({
    required this.isoWeekday,
    required this.slot,
    required this.mealName,
  });

  final int isoWeekday;
  final MealSlot slot;
  final String mealName;

  @override
  bool operator ==(Object other) =>
      other is MealPlanReason &&
      other.isoWeekday == isoWeekday &&
      other.slot == slot &&
      other.mealName == mealName;

  @override
  int get hashCode => Object.hash(isoWeekday, slot, mealName);
}

/// Lunch boxes this week: how many hold it, and whose.
final class LunchPlanReason extends GroceryNeedReason {
  const LunchPlanReason({required this.boxes, required this.childIds});

  final int boxes;
  final List<String> childIds;

  @override
  bool operator ==(Object other) =>
      other is LunchPlanReason &&
      other.boxes == boxes &&
      listEquals(other.childIds, childIds);

  @override
  int get hashCode => Object.hash(boxes, Object.hashAll(childIds));
}

/// A reason in a plug-in source's own words — "Running low".
final class LabelledReason extends GroceryNeedReason {
  const LabelledReason(this.label);

  final String label;

  @override
  bool operator ==(Object other) =>
      other is LabelledReason && other.label == label;

  @override
  int get hashCode => label.hashCode;
}
