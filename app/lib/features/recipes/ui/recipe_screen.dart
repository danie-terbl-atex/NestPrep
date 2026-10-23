import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../model/recipe.dart';
import '../state/recipe_catalogue_controller.dart';
import '../state/recipe_page_controller.dart';
import 'add_to_week_sheet.dart';
import 'recipe_page_body.dart';
import 'recipe_picture.dart';

/// One recipe's page, at `/households/:id/meals/recipes/:recipeId`
/// (recipes ADR-0003, `FE-17`): its photo edge to edge, then everything a
/// cook needs at the scale they choose, and — for somebody who may plan
/// meals — *Add to this week*.
///
/// The back button is there in every state, so a link to a retired recipe
/// is never a dead end; where it goes is the route's [onBack].
class RecipeScreen extends StatelessWidget {
  const RecipeScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecipePageController>();
    // Somebody who may only look at meals is not offered the write the rules
    // would refuse (household ADR-0003).
    final canPlan = context.watch<HouseholdView>().permissions.canEdit(
      HouseholdArea.meals,
    );
    final recipe = switch (controller.recipe) {
      AsyncData(:final value?) => value,
      _ => null,
    };
    return NestScaffold(
      isUnderStatusBar: true,
      bodyPadding: EdgeInsets.zero,
      floatingAction: canPlan && recipe != null
          ? NestButton(
              label: RecipeCopy.addToWeek,
              icon: LucideIcons.calendarPlus,
              isExpanded: false,
              isLoading: controller.isAdding,
              onPressed: () => _addToWeek(context, recipe),
            )
          : null,
      body: switch (controller.recipe) {
        AsyncLoading() => _Waiting(
          onBack: onBack,
          child: const NestSkeleton.rows(count: 6),
        ),
        AsyncFailure(:final failure) => _Waiting(
          onBack: onBack,
          child: NestErrorView(
            message: AppCopy.failure(failure),
            retryLabel: AppCopy.retry,
            // The recipe is the catalogue's one listener's to read again.
            onRetry: context.read<RecipeCatalogueController>().retry,
          ),
        ),
        AsyncData(value: null) => _Waiting(
          onBack: onBack,
          child: const NestEmptyView(
            icon: LucideIcons.bookX,
            title: RecipeCopy.missingTitle,
            message: RecipeCopy.pageMissingMessage,
          ),
        ),
        AsyncData(:final value?) => ListView(
          padding: const EdgeInsets.only(bottom: NestSpace.huge),
          children: [
            NestPhotoHero(
              photo: RecipePicture(path: value.photo?.hero),
              backLabel: AppCopy.back,
              onBack: onBack,
              semanticsLabel: RecipeCopy.photoOf(value.name),
            ),
            if (controller.actionFailure case final failure?)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  NestSpace.gutter,
                  0,
                  NestSpace.gutter,
                  NestSpace.lg,
                ),
                child: NestBanner(
                  message: AppCopy.failure(failure),
                  tone: NestBannerTone.danger,
                  actionLabel: AppCopy.back,
                  onAction: controller.dismissActionFailure,
                ),
              ),
            RecipePageBody(recipe: value),
          ],
        ),
      },
    );
  }

  Future<void> _addToWeek(BuildContext context, Recipe recipe) async {
    final controller = context.read<RecipePageController>();
    final people = controller.scale?.people ?? recipe.servings;
    final choice = await showAddToWeekSheet(
      context: context,
      recipe: recipe,
      people: people,
      today: context.read<HouseholdClock>().today,
    );
    if (choice == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final isAdded = await controller.addToWeek(
      day: choice.day,
      slot: choice.slot,
    );
    if (!isAdded) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          RecipeCopy.added(
            recipe.name,
            NestDates.weekdayName(choice.day),
            AppCopy.mealSlotName(choice.slot.name),
          ),
        ),
      ),
    );
  }
}

/// A recipe page with no recipe to show yet, or at all: the photo's place
/// held, the way back on it, and [child] — loading, failed, or gone — below.
class _Waiting extends StatelessWidget {
  const _Waiting({required this.onBack, required this.child});

  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestPhotoHero(
          photo: const RecipePicture(path: null),
          backLabel: AppCopy.back,
          onBack: onBack,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: NestSpace.gutter),
            child: child,
          ),
        ),
      ],
    );
  }
}
