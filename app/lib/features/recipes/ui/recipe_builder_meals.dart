import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe_context.dart';
import '../model/recipe_course.dart';
import '../model/recipe_form.dart';
import '../state/recipe_builder_controller.dart';

class RecipeBuilderMeals extends StatelessWidget {
  const RecipeBuilderMeals({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecipeBuilderController>();
    final placement = controller.form.placement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final meal in RecipeForm.offeredMeals)
              NestChip(
                key: ValueKey('recipe-meal-${meal.name}'),
                label: OwnRecipeCopy.mealName(meal),
                isSelected: placement.containsKey(meal),
                onTap: () => controller.update(
                  (form) =>
                      form.withMeal(meal, isOn: !placement.containsKey(meal)),
                ),
              ),
          ],
        ),
        for (final meal in RecipeForm.offeredMeals)
          if (placement[meal] case final chosen?)
            _CourseChoice(meal: meal, chosen: chosen),
      ],
    );
  }
}

class _CourseChoice extends StatelessWidget {
  const _CourseChoice({required this.meal, required this.chosen});

  final RecipeContext meal;
  final RecipeCourse chosen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.read<RecipeBuilderController>();
    return Padding(
      padding: const EdgeInsets.only(top: NestSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(OwnRecipeCopy.mealName(meal), style: nest.text.caption),
          const SizedBox(height: NestSpace.xs),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final course in RecipeCourse.values)
                NestChip(
                  key: ValueKey('recipe-course-${meal.name}-${course.name}'),
                  label: OwnRecipeCopy.courseName(course),
                  semanticLabel: OwnRecipeCopy.courseFor(meal, course),
                  isSelected: course == chosen,
                  onTap: () => controller.update(
                    (form) => form.withCourse(meal, course),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
