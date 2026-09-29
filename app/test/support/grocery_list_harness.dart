import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/groceries/ui/grocery_list_screen.dart';
import 'package:provider/provider.dart';

import 'fake_grocery_repository.dart';
import 'grocery_plan_harness.dart';
import 'household_fixtures.dart';
import 'pump_screen.dart';

/// The instant the grocery screen tests read.
final groceryNow = DateTime.utc(2026, 9, 17, 12);

/// A typed item on the list, bought at [boughtAt] when given.
GroceryItem groceryItem(String name, {String id = 'i', DateTime? boughtAt}) =>
    GroceryItem(
      id: id,
      name: name,
      addedBy: Fixtures.samMemberId,
      addedAt: groceryNow,
      boughtAt: boughtAt,
      boughtBy: boughtAt == null ? null : Fixtures.samMemberId,
    );

/// The grocery tab as its route builds it: the list's controller and, beside
/// it, the week's plans (groceries ADR-0002). Build one inside the test body,
/// so keep-in-step's writes settle with the pumps.
final class GroceryListHarness {
  GroceryListHarness() {
    controller = GroceryListController(
      groceryRepository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      now: () => groceryNow,
    );
    addTearDown(() async {
      controller.dispose();
      await repository.close();
      await plans.close();
    });
  }

  final repository = FakeGroceryRepository();
  final plans = GroceryPlanHarness();
  final selectedTabs = <HouseholdTab>[];
  late final GroceryListController controller;

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpScreen(
    tester,
    GroceryListScreen(onSelectTab: selectedTabs.add),
    providers: [
      ChangeNotifierProvider<GroceryListController>.value(value: controller),
      plans.provider,
    ],
    brightness: brightness,
    textScale: scale,
  );
}
