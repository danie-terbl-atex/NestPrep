import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/groceries/data/grocery_repository.dart';
import '../features/groceries/data/grocery_suggestion_source.dart';
import '../features/groceries/data/lunch_plan_grocery_source.dart';
import '../features/groceries/data/meal_plan_grocery_source.dart';
import '../features/groceries/state/grocery_list_controller.dart';
import '../features/groceries/state/grocery_plan_controller.dart';
import '../features/groceries/ui/grocery_list_screen.dart';
import '../features/groceries/ui/grocery_plan_wording.dart';
import '../features/household/model/household_area.dart';
import '../features/household/model/household_view.dart';
import '../features/lunch_box/data/lunch_repository.dart';
import '../features/lunch_box/data/lunch_week_reader.dart';
import '../features/lunch_box/model/lunch_week.dart';
import '../features/meal_planning/data/meal_repository.dart';
import '../shared/time/household_clock.dart';
import 'app_router.dart';
import 'household_route.dart';
import 'household_shell.dart';
import 'viewer_member.dart';

/// Everything that may put things on the grocery list (groceries ADR-0004).
///
/// **Plugging a source in is one line here.** Home-care's product stock
/// tracker adds its `GrocerySuggestionSource` to this list; the groceries
/// feature reads it for whoever may see its area, merges, dedups, proposes and
/// keeps in step exactly as it does the plans.
List<GrocerySuggestionSource> groceryPlanSources(BuildContext context) => [
  MealPlanGrocerySource(context.read<MealRepository>()),
  LunchPlanGrocerySource(LunchWeekReader(context.read<LunchRepository>())),
];

/// The grocery tab (groceries ADR-0002): the list, and beside it the week's
/// plans against the list — one controller each, both living as long as the
/// screen does (foundation ADR-0006).
GoRoute groceryRoute() => GoRoute(
  path: '${HouseholdRoute.path}/${HouseholdTab.groceries.segment}',
  builder: (context, state) {
    final householdId = HouseholdRoute.idFrom(state);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => GroceryListController(
            groceryRepository: context.read<GroceryRepository>(),
            householdId: householdId,
            memberId: viewerMemberIdOf(context),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => _planController(context, householdId),
        ),
      ],
      child: GroceryListScreen(
        onSelectTab: (tab) => goToTab(context, state, tab),
      ),
    );
  },
);

GroceryPlanController _planController(
  BuildContext context,
  String householdId,
) {
  final household = context.read<HouseholdView>();
  final permissions = household.permissions;
  final sources = groceryPlanSources(context);
  final visible = [
    for (final source in sources)
      if (permissions.canView(source.area)) source,
  ];
  final canEdit = permissions.canEdit(HouseholdArea.groceries);
  return GroceryPlanController(
    groceryRepository: context.read<GroceryRepository>(),
    // Somebody who only reads the list is never offered the plans, so the
    // plans are not read for them either.
    sources: canEdit ? visible : const [],
    wording: groceryPlanWording(household),
    householdId: householdId,
    memberId: viewerMemberIdOf(context),
    week: LunchWeek.planningFor(context.read<HouseholdClock>().today),
    canEdit: canEdit,
    seesEverySource: visible.length == sources.length,
  );
}
