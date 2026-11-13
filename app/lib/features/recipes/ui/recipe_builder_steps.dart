import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/own_recipe_limits.dart';
import '../model/recipe_form.dart';
import '../state/recipe_builder_controller.dart';
import 'recipe_builder_row.dart';
import 'recipe_text_sheet.dart';

class RecipeBuilderSteps extends StatelessWidget {
  const RecipeBuilderSteps({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<RecipeBuilderController>();
    final steps = controller.form.steps;
    return SliverReorderableList(
      itemCount: steps.length,
      proxyDecorator: recipeRowInFlight,
      onReorderItem: (from, to) =>
          controller.update((form) => form.withStepMoved(from, to)),
      itemBuilder: (context, index) {
        final step = steps[index];
        return RecipeBuilderRow(
          key: ValueKey(step.id),
          index: index,
          count: steps.length,
          title: step.text,
          titleStyle: nest.text.body,
          leading: Text(
            RecipeCopy.stepNumber(index + 1),
            style: nest.text.bodyStrong,
          ),
          removeLabel: OwnRecipeCopy.removeStep(index + 1),
          onEdit: () => showRecipeTextSheet(
            context: context,
            title: OwnRecipeCopy.stepLabel,
            label: OwnRecipeCopy.stepLabel,
            hint: OwnRecipeCopy.stepHint,
            submitLabel: OwnRecipeCopy.saveStep,
            limit: OwnRecipeLimits.step,
            maxLines: 5,
            initial: step.text,
            onSubmit: (text) => controller.update(
              (form) => form.withStepChanged(step.id, text),
            ),
          ),
          onRemove: () =>
              controller.update((form) => form.withoutStep(step.id)),
          onMove: (from, to) =>
              controller.update((form) => form.withStepMoved(from, to)),
        );
      },
    );
  }
}

class RecipeBuilderStepActions extends StatelessWidget {
  const RecipeBuilderStepActions({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<RecipeBuilderController>();
    final form = controller.form;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.shownProblems.contains(RecipeFormProblem.noSteps)) ...[
          Text(
            OwnRecipeCopy.missing(RecipeFormProblem.noSteps),
            style: nest.text.caption.copyWith(color: nest.colors.danger),
          ),
          const SizedBox(height: NestSpace.sm),
        ],
        if (!form.canAddStep) ...[
          Text(
            OwnRecipeCopy.stepsFull(OwnRecipeLimits.steps),
            style: nest.text.caption,
          ),
          const SizedBox(height: NestSpace.sm),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: NestButton(
            key: const ValueKey('recipe-add-step'),
            label: OwnRecipeCopy.addStep,
            icon: LucideIcons.plus,
            variant: NestButtonVariant.tonal,
            size: NestButtonSize.medium,
            isExpanded: false,
            onPressed: form.canAddStep
                ? () => showRecipeTextSheet(
                    context: context,
                    title: OwnRecipeCopy.addStep,
                    label: OwnRecipeCopy.stepLabel,
                    hint: OwnRecipeCopy.stepHint,
                    submitLabel: OwnRecipeCopy.addStep,
                    limit: OwnRecipeLimits.step,
                    maxLines: 5,
                    canAddMore: () => controller.form.canAddStep,
                    onSubmit: (text) =>
                        controller.update((form) => form.withStep(text)),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
