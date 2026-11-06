import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../recipes/model/family_size.dart';
import '../../recipes/model/recipe.dart';
import '../../recipes/ui/planned_recipe_thumb.dart';
import '../model/meal.dart';
import '../model/meal_week.dart';
import '../model/week_plan.dart';
import '../state/meal_plan_controller.dart';
import 'meal_ingredients_sheet.dart';
import 'slot_picker_sheet.dart';

typedef RecipePicker = Future<Recipe?> Function(
  MealSlot slot,
  CalendarDate day,
);

/// One day, with its three slots. An empty slot is a tap target that says it is
/// empty rather than a gap, so the week always reads as a grid (`FE-08`). A
/// meal planned from a recipe shows the recipe's photo and a way into it,
/// *How to make it*, of its own beside the slot's tap (recipes ADR-0003 §6).
class PlannedDayCard extends StatelessWidget {
  const PlannedDayCard({
    required this.day,
    required this.today,
    required this.library,
    required this.onOpenRecipe,
    required this.onPickRecipe,
    required this.onOpenLunch,
    super.key,
  });

  final PlannedDay day;
  final CalendarDate today;
  final List<Meal> library;
  final ValueChanged<String> onOpenRecipe;
  final RecipePicker onPickRecipe;
  final VoidCallback onOpenLunch;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final isToday = day.date == today;
    return NestCard(
      variant: isToday ? NestCardVariant.tinted : NestCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            NestDates.dayInARun(day.date, today),
            style: nest.text.bodyStrong.copyWith(
              color: isToday ? nest.colors.accentInk : nest.colors.ink,
            ),
          ),
          const SizedBox(height: NestSpace.sm),
          for (final slot in MealSlot.values)
            _SlotRow(
              date: day.date,
              slot: slot,
              meal: day.meals[slot],
              schoolLunchFor: slot == MealSlot.lunch
                  ? day.schoolLunchFor
                  : const [],
              library: library,
              onOpenRecipe: onOpenRecipe,
              onPickRecipe: onPickRecipe,
              onOpenLunch: onOpenLunch,
            ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.date,
    required this.slot,
    required this.meal,
    required this.schoolLunchFor,
    required this.library,
    required this.onOpenRecipe,
    required this.onPickRecipe,
    required this.onOpenLunch,
  });

  final CalendarDate date;
  final MealSlot slot;
  final Meal? meal;
  final List<String> schoolLunchFor;
  final List<Meal> library;
  final ValueChanged<String> onOpenRecipe;
  final RecipePicker onPickRecipe;
  final VoidCallback onOpenLunch;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final planned = meal;
    final recipeId = planned?.recipeId;
    final view = context.watch<HouseholdView>();
    final canEdit = view.permissions.canEdit(HouseholdArea.meals);
    final schoolNames = [
      for (final id in schoolLunchFor)
        ?view.memberById(id)?.displayName.split(' ').first,
    ]..sort();
    if (schoolNames.isNotEmpty) {
      return _SchoolLunchRow(
        names: schoolNames,
        atHome: planned,
        onOpenLunch: onOpenLunch,
        onPickAtHome: canEdit ? () => _pick(context) : null,
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(NestRadius.sm),
      onTap: canEdit ? () => _pick(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: NestSpace.sm),
        child: Row(
          children: [
            _SlotLabel(slot),
            if (recipeId != null) ...[
              PlannedRecipeThumb(recipeId: recipeId),
              const SizedBox(width: NestSpace.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planned?.name ?? AppCopy.mealsNothingPlanned,
                    style:
                        (recipeId != null
                                ? nest.text.bodyStrong
                                : nest.text.body)
                            .copyWith(
                              color: planned == null
                                  ? nest.colors.inkTertiary
                                  : nest.colors.ink,
                              fontStyle: planned == null
                                  ? FontStyle.italic
                                  : null,
                            ),
                  ),
                  if (recipeId != null)
                    NestButton(
                      label: RecipeCopy.howToMakeShort,
                      icon: LucideIcons.chefHat,
                      variant: NestButtonVariant.link,
                      size: NestButtonSize.small,
                      isExpanded: false,
                      onPressed: () => onOpenRecipe(recipeId),
                    ),
                ],
              ),
            ),
            Icon(
              planned == null ? LucideIcons.plus : LucideIcons.chevronRight,
              size: NestSize.iconSmall,
              color: nest.colors.inkTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final controller = context.read<MealPlanController>();
    final choice = await showSlotPickerSheet(
      context: context,
      slot: slot,
      date: date,
      today: controller.today,
      library: library,
      current: meal,
    );
    final slotKey = WeekPlan.slotKey(date.weekday, slot);
    switch (choice) {
      case null:
        return;
      case SlotCleared():
        await controller.clearSlot(slotKey);
      case SlotIngredients():
        final planned = meal;
        if (planned == null || !context.mounted) return;
        await showMealIngredientsSheet(
          context: context,
          meal: planned,
          controller: controller,
        );
      case SlotPicked(:final mealId):
        await controller.setSlot(slotKey, mealId);
      case SlotTyped(:final name):
        await controller.setSlotByName(slotKey, name);
      case SlotRecipe():
        if (!context.mounted) return;
        final familySize = familySizeOf(context.read<HouseholdView>());
        final recipe = await onPickRecipe(slot, date);
        if (recipe == null) return;
        await controller.setSlotFromRecipe(
          slotKey,
          recipe,
          familySize: familySize,
        );
    }
  }
}

class _SlotLabel extends StatelessWidget {
  const _SlotLabel(this.slot);

  final MealSlot slot;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return SizedBox(
      width: NestSize.avatarLarge + NestSpace.lg,
      child: Text(
        AppCopy.mealSlotName(slot.name),
        style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
      ),
    );
  }
}

class _SchoolLunchRow extends StatelessWidget {
  const _SchoolLunchRow({
    required this.names,
    required this.atHome,
    required this.onOpenLunch,
    required this.onPickAtHome,
  });

  final List<String> names;
  final Meal? atHome;
  final VoidCallback onOpenLunch;
  final VoidCallback? onPickAtHome;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final home = atHome;
    return Row(
      children: [
        const _SlotLabel(MealSlot.lunch),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(NestRadius.sm),
                onTap: onOpenLunch,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: NestSpace.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppCopy.mealsSchoolLunch(names),
                          style: nest.text.body.copyWith(
                            color: nest.colors.ink,
                          ),
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: NestSize.iconSmall,
                        color: nest.colors.inkTertiary,
                      ),
                    ],
                  ),
                ),
              ),
              if (home != null)
                InkWell(
                  borderRadius: BorderRadius.circular(NestRadius.sm),
                  onTap: onPickAtHome,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: NestSpace.sm),
                    child: Text(
                      AppCopy.mealsAtHome(home.name),
                      style: nest.text.caption.copyWith(
                        color: nest.colors.inkSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (home == null && onPickAtHome != null)
          NestIconButton(
            icon: LucideIcons.plus,
            label: AppCopy.mealsPlanLunchAtHome,
            variant: NestIconButtonVariant.plain,
            onPressed: onPickAtHome,
          ),
      ],
    );
  }
}
