import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe_form.dart';
import '../state/recipe_builder_controller.dart';
import 'recipe_builder_field.dart';

class RecipeBuilderNumbers extends StatelessWidget {
  const RecipeBuilderNumbers({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecipeBuilderController>();
    final form = controller.form;
    final problems = controller.shownProblems;
    String? errorFor(RecipeFormProblem problem) =>
        problems.contains(problem) ? OwnRecipeCopy.missing(problem) : null;
    return _NumberColumns(
      children: [
        RecipeBuilderField(
          key: const ValueKey('recipe-serves'),
          label: OwnRecipeCopy.serves,
          initial: form.servings,
          isNumber: true,
          limit: 2,
          errorText: errorFor(RecipeFormProblem.badServings),
          onChanged: (text) =>
              controller.update((form) => form.copyWith(servings: text)),
        ),
        RecipeBuilderField(
          key: const ValueKey('recipe-prep'),
          label: OwnRecipeCopy.prep,
          initial: form.prepMinutes,
          isNumber: true,
          limit: 4,
          errorText: errorFor(RecipeFormProblem.badPrepMinutes),
          onChanged: (text) =>
              controller.update((form) => form.copyWith(prepMinutes: text)),
        ),
        RecipeBuilderField(
          key: const ValueKey('recipe-cook'),
          label: OwnRecipeCopy.cook,
          initial: form.cookMinutes,
          isNumber: true,
          limit: 4,
          errorText: errorFor(RecipeFormProblem.badCookMinutes),
          onChanged: (text) =>
              controller.update((form) => form.copyWith(cookMinutes: text)),
        ),
      ],
    );
  }
}

class _NumberColumns extends StatelessWidget {
  const _NumberColumns({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final columns = MediaQuery.textScalerOf(context).scale(1) > 1.5 ? 1 : 3;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - NestSpace.md * (columns - 1)) / columns;
        return Wrap(
          spacing: NestSpace.md,
          runSpacing: NestSpace.md,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
