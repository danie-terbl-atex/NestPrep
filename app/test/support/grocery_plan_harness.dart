import 'package:nestprep/features/groceries/data/grocery_suggestion_source.dart';
import 'package:nestprep/features/groceries/model/grocery_need.dart';
import 'package:nestprep/features/groceries/model/grocery_need_reason.dart';
import 'package:nestprep/features/groceries/model/grocery_plan_settings.dart';
import 'package:nestprep/features/groceries/state/grocery_plan_controller.dart';
import 'package:nestprep/features/groceries/ui/grocery_plan_wording.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'fake_grocery_repository.dart';
import 'fake_grocery_source.dart';
import 'grocery_plan_fixtures.dart';
import 'household_fixtures.dart';

/// A plans controller over a fake list and two fake sources — the meals and
/// the lunch boxes — wired the way `grocery_route.dart` wires the real ones.
final class GroceryPlanHarness {
  GroceryPlanHarness({
    this.canEdit = true,
    this.seesEverySource = true,
    List<GrocerySuggestionSource>? extraSources,
  }) : repository = FakeGroceryRepository(echoPlanWrites: true) {
    controller = GroceryPlanController(
      groceryRepository: repository,
      sources: [meals, lunches, ...?extraSources],
      wording: groceryPlanWording(Fixtures.view()),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      week: week,
      canEdit: canEdit,
      seesEverySource: seesEverySource,
      now: () => planNow,
    );
  }

  static final week = LunchWeek.of(CalendarDate(2026, 9, 29));

  final bool canEdit;
  final bool seesEverySource;
  final FakeGroceryRepository repository;
  final meals = FakeGrocerySource(id: 'meals', area: HouseholdArea.meals);
  final lunches = FakeGrocerySource(id: 'lunch', area: HouseholdArea.lunch);
  late final GroceryPlanController controller;

  /// Every source and the list emit once, so the view is published.
  void open({
    List<GroceryNeed> mealNeeds = const [],
    List<GroceryNeed> lunchNeeds = const [],
    GroceryPlanSettings settings = GroceryPlanSettings.empty,
  }) {
    repository
      ..emitItems(const [])
      ..emitSettings(settings);
    meals.emit(mealNeeds);
    lunches.emit(lunchNeeds);
  }

  /// The plans controller as the grocery route provides it beside the list's.
  SingleChildWidget get provider =>
      ChangeNotifierProvider<GroceryPlanController>.value(value: controller);

  Future<void> close() async {
    controller.dispose();
    await meals.close();
    await lunches.close();
    await repository.close();
  }

  static GroceryNeed dinner(String name, int day) => GroceryNeed(
    name: name,
    reason: MealPlanReason(
      isoWeekday: day,
      slot: MealSlot.dinner,
      mealName: 'Spaghetti',
    ),
  );

  static GroceryNeed lunch(String name, int boxes) => GroceryNeed(
    name: name,
    reason: LunchPlanReason(boxes: boxes, childIds: const []),
  );
}
