import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/meal_ingredient_copy.dart';
import '../model/meal.dart';
import '../model/meal_ingredient.dart';
import '../state/meal_plan_controller.dart';
import 'ingredient_line_form.dart';

/// What goes in a meal (meal-planning ADR-0002): its lines, each removable,
/// and a form for the next. Saved as a whole, so a half-edited list is never
/// on anybody else's phone; the grocery list reads it when the meal is planned.
///
/// The controller is handed in because the sheet opens from other sheets,
/// which are routes above the screen's providers.
Future<void> showMealIngredientsSheet({
  required BuildContext context,
  required Meal meal,
  required MealPlanController controller,
}) {
  return showNestSheet<void>(
    context: context,
    title: MealIngredientCopy.title(meal.name),
    builder: (sheetContext) =>
        _MealIngredientsBody(meal: meal, controller: controller),
  );
}

class _MealIngredientsBody extends StatefulWidget {
  const _MealIngredientsBody({required this.meal, required this.controller});

  final Meal meal;
  final MealPlanController controller;

  @override
  State<_MealIngredientsBody> createState() => _MealIngredientsBodyState();
}

class _MealIngredientsBodyState extends State<_MealIngredientsBody> {
  late final _lines = List.of(widget.meal.ingredients);

  bool get _isFull => _lines.length >= MealIngredient.lineLimit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(MealIngredientCopy.intro, style: nest.text.bodySecondary),
              const SizedBox(height: NestSpace.md),
              if (_lines.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: NestSpace.md),
                  child: Text(
                    MealIngredientCopy.empty,
                    style: nest.text.body.copyWith(
                      color: nest.colors.inkTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              for (final (index, line) in _lines.indexed)
                NestListRow(
                  key: ValueKey('line-$index-${line.key}'),
                  title: MealIngredientCopy.line(line),
                  trailing: NestIconButton(
                    icon: LucideIcons.x,
                    label: MealIngredientCopy.remove(line.name),
                    variant: NestIconButtonVariant.plain,
                    onPressed: () => setState(() => _lines.removeAt(index)),
                  ),
                ),
              const SizedBox(height: NestSpace.lg),
              if (_isFull)
                NestBanner(
                  message: MealIngredientCopy.full(MealIngredient.lineLimit),
                )
              else
                IngredientLineForm(
                  onAdd: (line) => setState(() => _lines.add(line)),
                ),
            ],
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        NestButton(label: MealIngredientCopy.save, onPressed: _save),
      ],
    );
  }

  /// Closes first and writes after: offline, the write completes only when
  /// the network is back, and the library already shows it.
  Future<void> _save() async {
    Navigator.of(context).pop();
    await widget.controller.setIngredients(widget.meal.id, _lines);
  }
}
