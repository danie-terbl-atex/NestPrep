import 'package:nestprep/features/groceries/model/grocery_plan_settings.dart';

import 'model_fixtures.dart';

/// Groceries phase 2's stored models (groceries ADR-0002), for the round-trip
/// guard. The planned `GroceryItem` and the `Meal` with ingredients are in the
/// main list, beside their phase-1 shapes.
List<ModelFixture> groceryPlanModelFixtures(DateTime at) {
  final settings = GroceryPlanSettings(
    keepInStep: true,
    staples: const ['salt', 'olive oil'],
    updatedBy: 'm1',
    updatedAt: at,
  );
  return [
    ModelFixture(
      label: 'GroceryPlanSettings',
      id: GroceryPlanSettings.documentId,
      value: settings,
      toJson: settings.toJson,
      fromJson: GroceryPlanSettings.fromJson,
      keys: const {'keepInStep', 'staples', 'updatedBy', 'updatedAt'},
      note:
          'one document, `plans`; the rules accept no other id and at most '
          '200 staples.',
    ),
  ];
}
