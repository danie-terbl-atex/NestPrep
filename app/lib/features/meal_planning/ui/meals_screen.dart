import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../notifications/ui/notification_bell.dart';
import '../../recipes/model/recipe.dart';
import '../../recipes/ui/recipe_discovery_view.dart';
import '../../welcome_tour/model/tour_target.dart';
import '../../welcome_tour/ui/tour_anchor.dart';
import '../model/meals_view.dart';
import '../state/meal_plan_controller.dart';
import 'meal_library_sheet.dart';
import 'meal_week_view.dart';

/// The Meals tab (design-system ADR-0015): one header, and under it the
/// recipes to choose from — where it opens — or the week they go into,
/// switched by a segmented control whose choice is the route's [view]
/// (`FE-07`). Where a recipe opens and how the view changes are the route's
/// to decide; this lays out the two and reports what was asked (`FE-17`).
class MealsScreen extends StatelessWidget {
  const MealsScreen({
    required this.view,
    required this.onSelectView,
    required this.onSelectTab,
    required this.onOpenRecipe,
    super.key,
  });

  final MealsView view;
  final ValueChanged<MealsView> onSelectView;
  final ValueChanged<HouseholdTab> onSelectTab;

  /// A recipe by id — from a card, or from a meal planned from one.
  final ValueChanged<String> onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    final isWeek = view == MealsView.week;
    // The library is for somebody who may change meals (household
    // ADR-0003), and belongs beside the week it fills.
    final canEdit = context.watch<HouseholdView>().permissions.canEdit(
      HouseholdArea.meals,
    );
    return NestScaffold(
      title: AppCopy.mealsTitle,
      subtitle: isWeek
          ? NestDates.weekRange(context.watch<MealPlanController>().weekStart)
          : MealsCopy.recipesSubtitle,
      trailing: [
        if (isWeek && canEdit)
          NestIconButton(
            icon: LucideIcons.bookOpen,
            label: AppCopy.mealsManage,
            onPressed: () => showMealLibrarySheet(context: context),
          ),
        const NotificationBell(),
        const AccountMenuButton(),
      ],
      bottomBar: HouseholdTabBar(
        current: HouseholdTab.meals,
        onSelect: onSelectTab,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TourAnchor(
            target: TourTarget.mealsViews,
            child: NestSegmentedControl<MealsView>(
              segments: const [
                NestSegment(
                  value: MealsView.recipes,
                  label: MealsCopy.recipes,
                  icon: LucideIcons.bookOpenText,
                ),
                NestSegment(
                  value: MealsView.week,
                  label: MealsCopy.thisWeek,
                  icon: LucideIcons.calendarDays,
                ),
              ],
              selected: view,
              onSelect: onSelectView,
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          Expanded(
            child: isWeek
                ? MealWeekView(onOpenRecipe: onOpenRecipe)
                : RecipeDiscoveryView(
                    onOpen: (Recipe recipe) => onOpenRecipe(recipe.id),
                  ),
          ),
        ],
      ),
    );
  }
}
