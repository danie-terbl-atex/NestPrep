import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../meal_planning/model/week_plan.dart';
import '../model/recipe.dart';
import 'recipe_discovery_view.dart';

class RecipePickerScreen extends StatelessWidget {
  const RecipePickerScreen({
    required this.slot,
    required this.day,
    required this.today,
    required this.onPick,
    required this.onBack,
    super.key,
  });

  final MealSlot slot;
  final CalendarDate day;
  final CalendarDate today;
  final ValueChanged<Recipe> onPick;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return NestScaffold(
      leading: NestIconButton(
        icon: LucideIcons.arrowLeft,
        label: MealsCopy.pickerBack,
        onPressed: onBack,
      ),
      eyebrow:
          '${AppCopy.mealSlotName(slot.name)} · '
          '${NestDates.relative(day, today)}',
      title: MealsCopy.pickerTitle,
      body: RecipeDiscoveryView(onOpen: (recipe, _) => onPick(recipe)),
    );
  }
}
