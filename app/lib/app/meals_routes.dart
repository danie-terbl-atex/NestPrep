import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design/nest_kit.dart';
import '../features/household/model/household_area.dart';
import '../features/household/model/household_view.dart';
import '../features/lunch_box/data/lunch_repository.dart';
import '../features/lunch_box/data/lunch_week_reader.dart';
import '../features/lunch_box/model/lunch_week.dart';
import '../features/meal_planning/data/meal_repository.dart';
import '../features/meal_planning/model/meals_view.dart';
import '../features/meal_planning/state/meal_plan_controller.dart';
import '../features/meal_planning/ui/meals_screen.dart';
import '../features/photo_frames/data/photo_frame_repository.dart';
import '../features/photo_frames/state/frame_availability.dart';
import '../features/recipes/data/recipe_repository.dart';
import '../features/recipes/model/family_size.dart';
import '../features/recipes/model/recipe.dart';
import '../features/recipes/state/recipe_catalogue_controller.dart';
import '../features/recipes/state/recipe_page_controller.dart';
import '../features/recipes/ui/recipe_picker_screen.dart';
import '../features/recipes/ui/recipe_screen.dart';
import '../shared/flags/feature_flag.dart';
import '../shared/flags/feature_flags_controller.dart';
import '../shared/time/household_clock.dart';
import 'household_route.dart';
import 'household_tab_navigation.dart';
import 'meals_route.dart';
import 'viewer_member.dart';

/// The Meals tab's routes under the household shell (design-system
/// ADR-0015, recipes ADR-0003), in their own file so the route table gains
/// one line.
///
/// The catalogue is read once for the whole tab: the recipes view, a
/// recipe's page and the week's recipe-linked meals all read this one
/// listener (foundation ADR-0006), and a recipe opened over the list comes
/// back to it as it was left.
ShellRoute mealsRoutes() => ShellRoute(
  builder: (context, state, child) => ChangeNotifierProvider(
    create: (context) => RecipeCatalogueController(
      recipeRepository: context.read<RecipeRepository>(),
      householdClock: context.read<HouseholdClock>(),
    ),
    child: child,
  ),
  routes: [
    GoRoute(
      path: MealsRoute.path,
      builder: (context, state) {
        final householdId = HouseholdRoute.idFrom(state);
        return ChangeNotifierProvider(
          create: (context) => MealPlanController(
            mealRepository: context.read<MealRepository>(),
            householdClock: context.read<HouseholdClock>(),
            householdId: householdId,
            memberId: viewerMemberIdOf(context),
            watchPackedDays: _packedDaysFor(context, householdId),
          ),
          child: MealsScreen(
            view: MealsRoute.viewFrom(state),
            // A view is a place on the tab, not a step into it: switching
            // replaces rather than stacks, so back leaves the tab.
            onSelectView: (view) =>
                context.go(MealsRoute.pathFor(householdId, view: view)),
            onSelectTab: (tab) => goToTab(context, state, tab),
            onOpenRecipe: (recipeId, {heroTag}) => context.push(
              MealsRoute.recipePathFor(householdId, recipeId),
              extra: heroTag,
            ),
            onPickRecipe: (slot, day) => context.push<Recipe>(
              MealsRoute.pickPathFor(householdId, slot: slot, day: day),
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: MealsRoute.pickPath,
      redirect: (context, state) =>
          MealsRoute.slotFrom(state) == null ||
              MealsRoute.dayFrom(state) == null
          ? MealsRoute.pathFor(
              HouseholdRoute.idFrom(state),
              view: MealsView.week,
            )
          : null,
      builder: (context, state) {
        final householdId = HouseholdRoute.idFrom(state);
        return RecipePickerScreen(
          slot: MealsRoute.slotFrom(state)!,
          day: MealsRoute.dayFrom(state)!,
          today: context.read<HouseholdClock>().today,
          onPick: (recipe) => context.pop(recipe),
          onBack: () => context.canPop()
              ? context.pop()
              : context.go(
                  MealsRoute.pathFor(householdId, view: MealsView.week),
                ),
        );
      },
    ),
    GoRoute(
      path: MealsRoute.recipePath,
      pageBuilder: (context, state) {
        final householdId = HouseholdRoute.idFrom(state);
        final heroTag = switch (state.extra) {
          final String tag => tag,
          _ => null,
        };
        final page =
            ChangeNotifierProxyProvider<
              RecipeCatalogueController,
              RecipePageController
            >(
              create: (context) => RecipePageController(
                mealRepository: context.read<MealRepository>(),
                householdId: householdId,
                memberId: viewerMemberIdOf(context),
                recipeId: MealsRoute.recipeIdFrom(state),
                familySize: familySizeOf(context.read<HouseholdView>()),
              ),
              update: (context, catalogue, page) =>
                  page!..followCatalogue(catalogue),
              child:
                  ChangeNotifierProxyProvider<
                    FeatureFlagsController,
                    FrameAvailability
                  >(
                    create: (context) => FrameAvailability(
                      photoFrameRepository: context
                          .read<PhotoFrameRepository>(),
                      householdId: householdId,
                      isFamily: context
                          .read<HouseholdView>()
                          .permissions
                          .isFamily,
                    ),
                    update: (context, flags, availability) => availability!
                      ..followFlag(
                        framesOn: flags.isOn(FeatureFlag.photoFrames),
                      ),
                    child: RecipeScreen(
                      heroTag: heroTag,
                      // A link straight here has nothing under it: back is the
                      // recipes, never out of the app.
                      onBack: () => context.canPop()
                          ? context.pop()
                          : context.go(MealsRoute.pathFor(householdId)),
                    ),
                  ),
            );
        // Opened from a card, the page fades in under the card's flying
        // photo, as a lunch does; any other way, it arrives as pages do.
        return heroTag == null
            ? MaterialPage<void>(key: state.pageKey, child: page)
            : NestPhotoPage<void>(key: state.pageKey, child: page);
      },
    ),
  ],
);

PackedDaysWatch? _packedDaysFor(BuildContext context, String householdId) {
  final permissions = context.read<HouseholdView>().permissions;
  if (!permissions.canUse(HouseholdArea.lunch)) return null;
  final reader = LunchWeekReader(context.read<LunchRepository>());
  final ownChildId = permissions.hasOwnOnly(HouseholdArea.lunch)
      ? viewerMemberIdOf(context)
      : null;
  return (monday) => reader.watchPackedDays(
    householdId,
    LunchWeek.of(monday),
    ownChildId: ownChildId,
  );
}
