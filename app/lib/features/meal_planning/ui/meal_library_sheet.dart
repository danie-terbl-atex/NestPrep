import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/rename_sheet.dart';
import '../model/meal.dart';
import '../model/meal_week.dart';
import '../state/meal_plan_controller.dart';

/// Renames or deletes what the household eats. Deleting clears the slots that
/// used it, which the sheet says before it happens (meal-planning ADR-0001).
Future<void> showMealLibrarySheet({required BuildContext context}) {
  final controller = context.read<MealPlanController>();
  return showNestSheet<void>(
    context: context,
    title: AppCopy.mealsManage,
    builder: (sheetContext) => _MealLibraryBody(controller: controller),
  );
}

class _MealLibraryBody extends StatelessWidget {
  const _MealLibraryBody({required this.controller});

  final MealPlanController controller;

  @override
  Widget build(BuildContext context) {
    final library = switch (controller.week) {
      AsyncData<MealWeek>(value: final week) => week.library,
      _ => const <Meal>[],
    };
    if (library.isEmpty) {
      return const NestEmptyView(
        title: AppCopy.mealsEmptyTitle,
        message: AppCopy.mealsEmptyBody,
        icon: Icons.restaurant_outlined,
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final meal in library)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.xs),
              child: NestListRow(
                key: ValueKey(meal.id),
                title: meal.name,
                // Tapping the name edits it; the bin stays its own target, so
                // a mis-tap renames rather than deletes.
                onTap: () => _rename(context, meal),
                trailing: NestIconButton(
                  icon: Icons.delete_outline,
                  label: AppCopy.mealsDelete,
                  variant: NestIconButtonVariant.plain,
                  onPressed: () => _delete(context, meal),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// A meal typed in a hurry keeps its spelling for ever otherwise, and every
  /// week that used it shows the typo — the slot points at the meal, so a
  /// rename fixes all of them at once.
  Future<void> _rename(BuildContext context, Meal meal) async {
    final name = await showRenameSheet(
      context: context,
      title: AppCopy.mealsRename,
      label: AppCopy.mealsPickTitle,
      initial: meal.name,
    );
    if (name == null) return;
    await controller.renameMeal(meal.id, name);
  }

  Future<void> _delete(BuildContext context, Meal meal) async {
    final confirmed = await showNestConfirm(
      context: context,
      title: AppCopy.mealsDeleteConfirm,
      message: '${meal.name}\n\n${AppCopy.mealsDeleteBody}',
      confirmLabel: AppCopy.mealsDelete,
      cancelLabel: AppCopy.householdCancel,
      isDangerous: true,
    );
    if (confirmed != true) return;
    await controller.deleteMeal(meal.id);
  }
}
