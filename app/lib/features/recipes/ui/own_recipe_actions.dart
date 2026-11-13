import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../model/recipe.dart';
import '../state/own_recipe_deleter.dart';
import '../state/recipe_catalogue_controller.dart';
import '../state/recipe_page_controller.dart';
import 'own_recipe_access.dart';

class OwnRecipeActions extends StatelessWidget {
  const OwnRecipeActions({
    required this.recipe,
    required this.onEdit,
    required this.onDeleted,
    super.key,
  });

  final Recipe recipe;
  final VoidCallback onEdit;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final access = OwnRecipeAccess.of(context);
    if (!access.canDelete) return const SizedBox.shrink();
    final deleter = context.watch<OwnRecipeDeleter>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (deleter.actionFailure case final failure?) ...[
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
            actionLabel: AppCopy.back,
            onAction: deleter.dismissActionFailure,
          ),
          const SizedBox(height: NestSpace.sm),
        ],
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            if (access.canAddOrEdit)
              NestButton(
                key: const ValueKey('own-recipe-edit'),
                label: OwnRecipeCopy.edit,
                icon: LucideIcons.pencil,
                variant: NestButtonVariant.tonal,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: () => _edit(context),
              ),
            NestButton(
              key: const ValueKey('own-recipe-delete'),
              label: OwnRecipeCopy.delete,
              icon: LucideIcons.trash2,
              variant: NestButtonVariant.outline,
              size: NestButtonSize.small,
              isExpanded: false,
              isLoading: deleter.isDeleting,
              onPressed: () => _delete(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context) async {
    if (!await ensurePremium(context, feature: PremiumFeature.ownRecipes)) {
      return;
    }
    if (context.mounted) onEdit();
  }

  Future<void> _delete(BuildContext context) async {
    final isSure = await showNestConfirm(
      context: context,
      title: OwnRecipeCopy.deleteTitle,
      message: OwnRecipeCopy.deleteMessage(recipe.name),
      confirmLabel: OwnRecipeCopy.deleteConfirm,
      cancelLabel: OwnRecipeCopy.deleteCancel,
      isDangerous: true,
    );
    if (isSure != true || !context.mounted) return;
    final deleter = context.read<OwnRecipeDeleter>();
    final page = context.read<RecipePageController>();
    final catalogue = context.read<RecipeCatalogueController>();
    final messenger = ScaffoldMessenger.of(context);
    page.holdRecipe();
    final isDeleted = await deleter.delete(recipe);
    if (!context.mounted) return;
    if (isDeleted) {
      messenger.showSnackBar(
        const SnackBar(content: Text(OwnRecipeCopy.deleted)),
      );
      onDeleted();
    } else {
      page.releaseRecipe(catalogue);
    }
  }
}
