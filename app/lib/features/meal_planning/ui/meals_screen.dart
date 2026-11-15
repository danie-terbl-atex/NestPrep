import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/food_switch.dart';
import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../notifications/ui/notification_bell.dart';
import '../../recipes/ui/recipe_discovery_view.dart';
import '../../starter_content/ui/starter_examples_banner.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/premium_area.dart';
import '../../welcome_tour/model/tour_target.dart';
import '../../welcome_tour/ui/tour_anchor.dart';
import '../model/meals_view.dart';
import '../state/meal_plan_controller.dart';
import 'meal_library_sheet.dart';
import 'meal_week_view.dart';
import 'planned_day_card.dart';

/// Meals, under the Food tab (design-system ADR-0015, ADR-0017): one header, and under it the
/// recipes to choose from or the week they go into, switched by a segmented
/// control whose choice is the route's [view] (`FE-07`). Where a recipe opens
/// and how the view changes are the route's to decide; this lays out the two
/// and reports what was asked (`FE-17`).
///
/// Recipes are Premium and the week is free (subscriptions ADR-0008): a
/// household without Premium opens on the week, and its recipes are shown
/// locked, never hidden.
class MealsScreen extends StatelessWidget {
  const MealsScreen({
    required this.view,
    required this.onSelectView,
    required this.onSelectTab,
    required this.onOpenRecipe,
    required this.onPickRecipe,
    this.recipesEntry,
    super.key,
  });

  /// Null when the route named none: the recipes with Premium, else the week.
  final MealsView? view;
  final ValueChanged<MealsView> onSelectView;
  final ValueChanged<HouseholdTab> onSelectTab;

  /// A recipe by id — from a card, whose photo flies by [heroTag], or from
  /// a meal planned from one.
  final void Function(String recipeId, {String? heroTag}) onOpenRecipe;

  final RecipePicker onPickRecipe;
  final Widget? recipesEntry;

  @override
  Widget build(BuildContext context) {
    final entitlement = context.watch<HouseholdEntitlement>();
    final hasRecipes = entitlement.isPremium;
    final isChecking = entitlement.entitlement is AsyncLoading;
    final shown =
        view ?? (hasRecipes || isChecking ? MealsView.recipes : MealsView.week);
    final isWeek = shown == MealsView.week;
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
          FoodSwitch(current: HouseholdTab.meals, onSelect: onSelectTab),
          if (isWeek)
            StarterExamplesBanner(
              shownIds: switch (context.watch<MealPlanController>().week) {
                AsyncData(:final value) => [
                  for (final meal in value.library) meal.id,
                ],
                _ => const [],
              },
            ),
          TourAnchor(
            target: TourTarget.mealsViews,
            child: NestSegmentedControl<MealsView>(
              segments: [
                NestSegment(
                  value: MealsView.recipes,
                  label: MealsCopy.recipes,
                  icon: hasRecipes || isChecking
                      ? LucideIcons.bookOpenText
                      : LucideIcons.lock,
                  hint: hasRecipes || isChecking
                      ? null
                      : SubscriptionCopy.lockedHint,
                ),
                const NestSegment(
                  value: MealsView.week,
                  label: MealsCopy.thisWeek,
                  icon: LucideIcons.calendarDays,
                ),
              ],
              selected: shown,
              onSelect: onSelectView,
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          Expanded(
            child: isWeek
                ? MealWeekView(
                    onOpenRecipe: onOpenRecipe,
                    onPickRecipe: onPickRecipe,
                    onOpenLunch: () => onSelectTab(HouseholdTab.lunch),
                  )
                : hasRecipes
                ? RecipeDiscoveryView(
                    addEntry: recipesEntry,
                    onOpen: (recipe, heroTag) =>
                        onOpenRecipe(recipe.id, heroTag: heroTag),
                  )
                : isChecking
                ? const NestLoadingView()
                : const PremiumLockedView(feature: PremiumFeature.recipes),
          ),
        ],
      ),
    );
  }
}
