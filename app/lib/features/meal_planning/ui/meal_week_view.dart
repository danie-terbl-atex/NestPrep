import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../model/meal_week.dart';
import '../state/meal_plan_controller.dart';
import 'planned_day_card.dart';

/// The Meals tab's *This week* (meal-planning ADR-0001): the week's
/// twenty-one slots, a week either side, and copying last week forward. One
/// document is the whole week, so this is one listener and reads offline
/// from a single cached document. A slot planned from a recipe opens it
/// through [onOpenRecipe] (recipes ADR-0003 §6).
class MealWeekView extends StatelessWidget {
  const MealWeekView({
    required this.onOpenRecipe,
    required this.onPickRecipe,
    super.key,
  });

  final ValueChanged<String> onOpenRecipe;
  final RecipePicker onPickRecipe;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MealPlanController>();
    final failure = controller.actionFailure;
    // A plan somebody may only read: no copying, no picking (household
    // ADR-0003).
    final canEdit = context.watch<HouseholdView>().permissions.canEdit(
      HouseholdArea.meals,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (failure != null)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.md),
            child: NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.back,
              onAction: controller.dismissActionFailure,
            ),
          ),
        Row(
          children: [
            NestIconButton(
              icon: LucideIcons.chevronLeft,
              label: AppCopy.calendarPreviousWeek,
              variant: NestIconButtonVariant.plain,
              onPressed: controller.goToPreviousWeek,
            ),
            Expanded(
              child: NestButton(
                label: AppCopy.mealsCopyLastWeek,
                icon: LucideIcons.copy,
                variant: NestButtonVariant.tonal,
                size: NestButtonSize.small,
                isLoading: controller.isCopying,
                onPressed: canEdit ? controller.copyLastWeek : null,
              ),
            ),
            NestIconButton(
              icon: LucideIcons.chevronRight,
              label: AppCopy.calendarNextWeek,
              variant: NestIconButtonVariant.plain,
              onPressed: controller.goToNextWeek,
            ),
          ],
        ),
        const SizedBox(height: NestSpace.lg),
        Expanded(
          child: NestAsyncView<MealWeek>(
            state: controller.week,
            // The grid is the empty state: twenty-one slots that each say
            // they are empty and each open the picker. Replacing it with a
            // blank view would take away the only way to plan the first meal
            // (`FE-08`).
            isEmpty: (_) => false,
            onRetry: controller.retry,
            emptyBuilder: (_) => const SizedBox.shrink(),
            dataBuilder: (_, week) => ListView(
              padding: const EdgeInsets.only(
                bottom: NestSize.bottomBarHeight * 2,
              ),
              children: [
                if (week.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: NestSpace.md),
                    child: NestBanner(message: AppCopy.mealsEmptyBody),
                  ),
                for (final day in week.days)
                  Padding(
                    padding: const EdgeInsets.only(bottom: NestSpace.md),
                    child: PlannedDayCard(
                      key: ValueKey(day.date.iso),
                      day: day,
                      today: week.today,
                      library: week.library,
                      onOpenRecipe: onOpenRecipe,
                      onPickRecipe: onPickRecipe,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
