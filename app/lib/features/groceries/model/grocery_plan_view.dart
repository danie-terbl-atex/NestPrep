import 'package:flutter/foundation.dart';

import '../../lunch_box/model/lunch_week.dart';
import 'grocery_plan_diff.dart';
import 'grocery_plan_settings.dart';

/// What the plans sheet and the prompt on the list render: the week, what
/// its plans would change, and the household's settings — derived once per
/// emission, never in a build method (`FE-12`).
@immutable
class GroceryPlanView {
  const GroceryPlanView({
    required this.week,
    required this.diff,
    required this.settings,
    required this.canKeepInStep,
  });

  final LunchWeek week;
  final GroceryPlanDiff diff;
  final GroceryPlanSettings settings;

  /// Whether this viewer may turn keeping in step on: they edit the list and
  /// see every plan it is kept in step with (groceries ADR-0002).
  final bool canKeepInStep;

  bool get isKeptInStep => settings.keepInStep;

  /// How many changes the plans would make — what the prompt counts.
  int get changeCount =>
      diff.toAdd.length + diff.toRefresh.length + diff.toRemove.length;
}
