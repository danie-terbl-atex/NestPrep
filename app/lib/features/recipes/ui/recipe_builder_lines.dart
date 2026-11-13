import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/own_recipe_limits.dart';
import '../model/recipe_form.dart';
import '../state/recipe_builder_controller.dart';
import 'recipe_builder_row.dart';
import 'recipe_line_sheet.dart';
import 'recipe_text_sheet.dart';

class RecipeBuilderLines extends StatelessWidget {
  const RecipeBuilderLines({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<RecipeBuilderController>();
    final entries = controller.form.entries;
    return SliverReorderableList(
      itemCount: entries.length,
      proxyDecorator: recipeRowInFlight,
      onReorderItem: (from, to) =>
          controller.update((form) => form.withEntryMoved(from, to)),
      itemBuilder: (context, index) => switch (entries[index]) {
        final RecipeFormHeading heading => RecipeBuilderRow(
          key: ValueKey(heading.id),
          index: index,
          count: entries.length,
          title: heading.text,
          titleStyle: nest.text.title,
          removeLabel: OwnRecipeCopy.removeHeading(heading.text),
          onEdit: () => editRecipeHeading(context, heading),
          onRemove: () =>
              controller.update((form) => form.withoutEntry(heading.id)),
          onMove: (from, to) =>
              controller.update((form) => form.withEntryMoved(from, to)),
        ),
        final RecipeFormLine line => RecipeBuilderRow(
          key: ValueKey(line.id),
          index: index,
          count: entries.length,
          title: RecipeCopy.ingredient(
            name: line.name,
            quantity: line.amount,
            unit: line.unit?.code,
            note: line.note,
          ),
          titleStyle: nest.text.body,
          removeLabel: OwnRecipeCopy.removeIngredient(line.name),
          onEdit: () => showRecipeLineSheet(
            context: context,
            line: line,
            onSubmit: (changed) =>
                controller.update((form) => form.withEntryChanged(changed)),
          ),
          onRemove: () =>
              controller.update((form) => form.withoutEntry(line.id)),
          onMove: (from, to) =>
              controller.update((form) => form.withEntryMoved(from, to)),
        ),
      },
    );
  }
}

class RecipeBuilderLineActions extends StatelessWidget {
  const RecipeBuilderLineActions({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<RecipeBuilderController>();
    final form = controller.form;
    final problems = controller.shownProblems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (problems.contains(RecipeFormProblem.noIngredients)) ...[
          Text(
            OwnRecipeCopy.missing(RecipeFormProblem.noIngredients),
            style: nest.text.caption.copyWith(color: nest.colors.danger),
          ),
          const SizedBox(height: NestSpace.sm),
        ],
        if (!form.canAddLine) ...[
          Text(
            OwnRecipeCopy.ingredientsFull(OwnRecipeLimits.ingredients),
            style: nest.text.caption,
          ),
          const SizedBox(height: NestSpace.sm),
        ],
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            NestButton(
              key: const ValueKey('recipe-add-line'),
              label: OwnRecipeCopy.addIngredient,
              icon: LucideIcons.plus,
              variant: NestButtonVariant.tonal,
              size: NestButtonSize.medium,
              isExpanded: false,
              onPressed: form.canAddLine
                  ? () => showRecipeLineSheet(
                      context: context,
                      canAddMore: () => controller.form.canAddLine,
                      onSubmit: (line) => controller.update(
                        (form) => form.withLine(
                          name: line.name,
                          amount: line.amount,
                          unit: line.unit,
                          note: line.note,
                        ),
                      ),
                    )
                  : null,
            ),
            NestButton(
              key: const ValueKey('recipe-add-heading'),
              label: OwnRecipeCopy.addHeading,
              icon: LucideIcons.heading,
              variant: NestButtonVariant.outline,
              size: NestButtonSize.medium,
              isExpanded: false,
              onPressed: () => showRecipeTextSheet(
                context: context,
                title: OwnRecipeCopy.addHeading,
                label: OwnRecipeCopy.headingLabel,
                hint: OwnRecipeCopy.headingHint,
                submitLabel: OwnRecipeCopy.saveHeading,
                limit: OwnRecipeLimits.ingredientGroup,
                onSubmit: (text) =>
                    controller.update((form) => form.withHeading(text)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> editRecipeHeading(
  BuildContext context,
  RecipeFormHeading heading,
) {
  final controller = context.read<RecipeBuilderController>();
  return showRecipeTextSheet(
    context: context,
    title: OwnRecipeCopy.headingLabel,
    label: OwnRecipeCopy.headingLabel,
    hint: OwnRecipeCopy.headingHint,
    submitLabel: OwnRecipeCopy.saveHeading,
    limit: OwnRecipeLimits.ingredientGroup,
    initial: heading.text,
    onSubmit: (text) => controller.update(
      (form) =>
          form.withEntryChanged(RecipeFormHeading(id: heading.id, text: text)),
    ),
  );
}
