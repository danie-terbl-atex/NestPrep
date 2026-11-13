import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe.dart';
import '../model/recipe_photo.dart';
import '../state/recipe_page_controller.dart';
import 'open_on_frame_button.dart';
import 'own_recipe_actions.dart';
import 'own_recipe_source_link.dart';
import 'people_scaler.dart';
import 'recipe_allergens.dart';
import 'recipe_facts.dart';
import 'recipe_ingredient_list.dart';
import 'recipe_make_ahead.dart';
import 'recipe_photo_credit.dart';
import 'recipe_shop_card.dart';
import 'recipe_step_row.dart';

/// Everything under a recipe's photo, in the order a cook needs it: what it
/// is, how long, what is in it that matters, the ways of eating it suits,
/// where it comes from; then how
/// many it is for, what to gather at that scale, and how to make it; then
/// whose photo it was. Ticks, done steps and the scale are the page's
/// controller's; this lays them out and reports taps.
class RecipePageBody extends StatelessWidget {
  const RecipePageBody({
    required this.recipe,
    this.onEdit,
    this.onDeleted,
    super.key,
  });

  final Recipe recipe;
  final VoidCallback? onEdit;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<RecipePageController>();
    final scale = controller.scale;
    final about = recipe.about;
    final prepNote = recipe.prepNote;
    final notes = recipe.notes;
    final edit = onEdit;
    final deleted = onDeleted;
    final credited = <String?, RecipePhoto>{
      for (final photo
          in recipe.isOwn
              ? [?recipe.photo, ...recipe.gallery]
              : [?recipe.photo])
        photo.credit: photo,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NestSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(recipe.name, style: nest.text.display),
          if (recipe.summary.isNotEmpty) ...[
            const SizedBox(height: NestSpace.sm),
            Text(recipe.summary, style: nest.text.bodySecondary),
          ],
          if (recipe.isOwn) ...[
            OwnRecipeSourceLink(recipe: recipe),
            if (edit != null && deleted != null) ...[
              const SizedBox(height: NestSpace.sm),
              OwnRecipeActions(
                recipe: recipe,
                onEdit: edit,
                onDeleted: deleted,
              ),
            ],
          ],
          const SizedBox(height: NestSpace.xl),
          RecipeFacts(recipe: recipe),
          const SizedBox(height: NestSpace.xl),
          const NestEyebrow(RecipeCopy.allergensHeader),
          const SizedBox(height: NestSpace.sm),
          RecipeAllergens(allergens: recipe.allergens, isOwn: recipe.isOwn),
          if (recipe.dietTags.isNotEmpty) ...[
            const SizedBox(height: NestSpace.xl),
            const NestEyebrow(RecipeCopy.dietHeader),
            const SizedBox(height: NestSpace.sm),
            Wrap(
              spacing: NestSpace.xs,
              runSpacing: NestSpace.xs,
              children: [
                for (final tag in recipe.dietTags)
                  NestTag(label: RecipeCopy.dietTag(tag)),
              ],
            ),
          ],
          if (about != null) ...[
            const SizedBox(height: NestSpace.xxl),
            const NestSectionHeader(title: RecipeCopy.aboutHeader),
            const SizedBox(height: NestSpace.sm),
            Text(about, style: nest.text.body),
          ],
          if (scale != null) ...[
            const SizedBox(height: NestSpace.xxl),
            PeopleScaler(
              scale: scale,
              onAdd: controller.addPerson,
              onRemove: controller.removePerson,
              onReset: controller.resetToRecipe,
            ),
            OpenOnFrameButton(recipe: recipe, scale: scale),
          ],
          const SizedBox(height: NestSpace.xxxl),
          const NestSectionHeader(title: RecipeCopy.ingredientsHeader),
          const SizedBox(height: NestSpace.sm),
          RecipeIngredientList(
            groups: controller.groups,
            isTicked: controller.isTicked,
            onToggle: controller.toggleIngredient,
          ),
          const SizedBox(height: NestSpace.xl),
          const RecipeShopCard(),
          const SizedBox(height: NestSpace.xxxl),
          const NestSectionHeader(title: RecipeCopy.stepsHeader),
          const SizedBox(height: NestSpace.xs),
          for (final (index, step) in recipe.steps.indexed)
            RecipeStepRow(
              key: ValueKey('step-$index'),
              number: index + 1,
              step: step,
              isDone: controller.isDone(index),
              onToggle: () => controller.toggleStep(index),
            ),
          if (prepNote != null) ...[
            const SizedBox(height: NestSpace.xxl),
            RecipeMakeAhead(note: prepNote),
          ],
          if (notes != null) ...[
            const SizedBox(height: NestSpace.xxl),
            const NestSectionHeader(title: OwnRecipeCopy.tips),
            const SizedBox(height: NestSpace.sm),
            Text(notes, style: nest.text.body),
          ],
          for (final photo in credited.values)
            if (!recipe.isOwn || photo.credit != null) ...[
              const SizedBox(height: NestSpace.xxl),
              RecipePhotoCredit(photo: photo, isOwn: recipe.isOwn),
            ],
        ],
      ),
    );
  }
}
