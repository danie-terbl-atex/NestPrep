import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/links/external_link_opener.dart';
import '../../home_care/ui/form_section.dart';
import '../model/own_recipe_limits.dart';
import '../model/recipe_form.dart';
import '../state/recipe_builder_controller.dart';
import 'recipe_builder_allergens.dart';
import 'recipe_builder_field.dart';
import 'recipe_builder_lines.dart';
import 'recipe_builder_meals.dart';
import 'recipe_builder_numbers.dart';
import 'recipe_builder_photos.dart';
import 'recipe_builder_steps.dart';

class RecipeBuilderScreen extends StatelessWidget {
  const RecipeBuilderScreen({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecipeBuilderController>();
    final problems = controller.shownProblems;
    final form = controller.form;
    String? errorFor(RecipeFormProblem problem) =>
        problems.contains(problem) ? OwnRecipeCopy.missing(problem) : null;
    return PopScope(
      canPop: !controller.isDirty && !controller.isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(context);
      },
      child: NestScaffold(
        leading: NestIconButton(
          icon: LucideIcons.arrowLeft,
          label: AppCopy.back,
          onPressed: () => _leave(context),
        ),
        title: controller.isEditing
            ? OwnRecipeCopy.editTitle
            : OwnRecipeCopy.newTitle,
        body: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (controller.isCutShort) ...[
                    _CutShortBanner(sourceUrl: form.sourceUrl),
                    const SizedBox(height: NestSpace.lg),
                  ],
                  const FormSection(
                    label: OwnRecipeCopy.photosHeader,
                    child: RecipeBuilderPhotos(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: NestSpace.xl),
                    child: RecipeBuilderField(
                      key: const ValueKey('recipe-name'),
                      label: OwnRecipeCopy.name,
                      hint: OwnRecipeCopy.nameHint,
                      initial: form.name,
                      limit: OwnRecipeLimits.name,
                      errorText: errorFor(RecipeFormProblem.noName),
                      onChanged: (text) => controller.update(
                        (form) => form.copyWith(name: text),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: NestSpace.xl),
                    child: RecipeBuilderField(
                      key: const ValueKey('recipe-summary'),
                      label: OwnRecipeCopy.description,
                      hint: OwnRecipeCopy.descriptionHint,
                      initial: form.summary,
                      limit: OwnRecipeLimits.summary,
                      maxLines: 3,
                      onChanged: (text) => controller.update(
                        (form) => form.copyWith(summary: text),
                      ),
                    ),
                  ),
                  FormSection(
                    label: OwnRecipeCopy.mealsHeader,
                    errorText: errorFor(RecipeFormProblem.noMeal),
                    child: const RecipeBuilderMeals(),
                  ),
                  const FormSection(
                    label: OwnRecipeCopy.numbersHeader,
                    child: RecipeBuilderNumbers(),
                  ),
                  const NestSectionHeader(title: RecipeCopy.ingredientsHeader),
                  const SizedBox(height: NestSpace.sm),
                ],
              ),
            ),
            const RecipeBuilderLines(),
            const SliverPadding(
              padding: EdgeInsets.only(top: NestSpace.sm, bottom: NestSpace.xl),
              sliver: SliverToBoxAdapter(child: RecipeBuilderLineActions()),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: NestSpace.sm),
                child: NestSectionHeader(title: RecipeCopy.stepsHeader),
              ),
            ),
            const RecipeBuilderSteps(),
            const SliverPadding(
              padding: EdgeInsets.only(top: NestSpace.sm, bottom: NestSpace.xl),
              sliver: SliverToBoxAdapter(child: RecipeBuilderStepActions()),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: NestSpace.xl),
                    child: RecipeBuilderField(
                      key: const ValueKey('recipe-notes'),
                      label: OwnRecipeCopy.tips,
                      hint: OwnRecipeCopy.tipsHint,
                      initial: form.notes,
                      limit: OwnRecipeLimits.notes,
                      maxLines: 5,
                      onChanged: (text) => controller.update(
                        (form) => form.copyWith(notes: text),
                      ),
                    ),
                  ),
                  const FormSection(
                    label: RecipeCopy.allergensHeader,
                    child: RecipeBuilderAllergens(),
                  ),
                  if (problems.isNotEmpty) ...[
                    const NestBanner(
                      message: OwnRecipeCopy.fixTheMarked,
                      tone: NestBannerTone.warning,
                    ),
                    const SizedBox(height: NestSpace.md),
                  ],
                  if (controller.actionFailure case final failure?) ...[
                    NestBanner(
                      key: const ValueKey('recipe-builder-failure'),
                      message: AppCopy.failure(failure),
                      tone: NestBannerTone.danger,
                      actionLabel: AppCopy.back,
                      onAction: controller.dismissActionFailure,
                    ),
                    const SizedBox(height: NestSpace.md),
                  ],
                  NestButton(
                    key: const ValueKey('recipe-save'),
                    label: OwnRecipeCopy.save,
                    isLoading: controller.isSaving,
                    onPressed: () => _save(context),
                  ),
                  const SizedBox(height: NestSpace.huge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final controller = context.read<RecipeBuilderController>();
    final messenger = ScaffoldMessenger.of(context);
    if (!await controller.save() || !context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          controller.missedMealLines
              ? OwnRecipeCopy.savedButWeekIsOld
              : OwnRecipeCopy.saved,
        ),
      ),
    );
    onDone();
  }

  Future<void> _leave(BuildContext context) async {
    final controller = context.read<RecipeBuilderController>();
    if (controller.isSaving) return;
    if (!controller.isDirty) return onDone();
    final isSure = await showNestConfirm(
      context: context,
      title: OwnRecipeCopy.leaveTitle,
      message: OwnRecipeCopy.leaveMessage,
      confirmLabel: OwnRecipeCopy.leaveConfirm,
      cancelLabel: OwnRecipeCopy.leaveCancel,
      isDangerous: true,
    );
    if (isSure == true && context.mounted) onDone();
  }
}

class _CutShortBanner extends StatelessWidget {
  const _CutShortBanner({required this.sourceUrl});

  final String? sourceUrl;

  @override
  Widget build(BuildContext context) {
    final original = Uri.tryParse(sourceUrl ?? '');
    return Column(
      key: const ValueKey('recipe-cut-short'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestBanner(
          message: OwnRecipeCopy.cutShort,
          tone: NestBannerTone.warning,
        ),
        if (original != null && original.hasAuthority)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: NestButton(
              key: const ValueKey('recipe-open-original'),
              label: OwnRecipeCopy.openOriginal,
              icon: LucideIcons.externalLink,
              variant: NestButtonVariant.link,
              size: NestButtonSize.small,
              isExpanded: false,
              onPressed: () =>
                  context.read<ExternalLinkOpener>().open(original),
            ),
          ),
      ],
    );
  }
}
