import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../model/recipe_draft.dart';
import '../model/recipe_facet.dart';
import '../model/recipe_import_way.dart';
import '../state/recipe_catalogue_controller.dart';
import 'own_recipe_access.dart';

enum RecipeAddWay { type, link, snap, pdf }

class OwnRecipesEntry extends StatelessWidget {
  const OwnRecipesEntry({
    required this.onOpenBuilder,
    required this.onImport,
    required this.onImportPdf,
    super.key,
  });

  /// Null opens it empty.
  final ValueChanged<RecipeDraft?> onOpenBuilder;
  final ValueChanged<RecipeImportWay> onImport;
  final VoidCallback onImportPdf;

  @override
  Widget build(BuildContext context) {
    if (!OwnRecipeAccess.of(context).canAddOrEdit) {
      return const SizedBox.shrink();
    }
    final isPremium = context.watch<HouseholdEntitlement>().isPremium;
    final hasOwn = context.select<RecipeCatalogueController, bool>(
      (catalogue) => switch (catalogue.catalogue) {
        AsyncData(:final value) => value.facets.contains(RecipeFacet.ours),
        _ => false,
      },
    );
    if (isPremium && hasOwn) {
      return NestButton(
        key: const ValueKey('own-recipes-add'),
        label: OwnRecipeCopy.addAction,
        icon: LucideIcons.plus,
        variant: NestButtonVariant.tonal,
        onPressed: () => _add(context),
      );
    }
    final nest = NestTheme.of(context);
    return NestCard(
      key: const ValueKey('own-recipes-card'),
      variant: NestCardVariant.tinted,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const NestIconTile(
                icon: LucideIcons.bookHeart,
                tint: NestTileTint.butter,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Text(OwnRecipeCopy.addTitle, style: nest.text.title),
              ),
              if (!isPremium) ...[
                const SizedBox(width: NestSpace.sm),
                const NestTag(
                  label: OwnRecipeCopy.premiumTag,
                  tone: NestTagTone.accent,
                  icon: LucideIcons.award,
                ),
              ],
            ],
          ),
          const SizedBox(height: NestSpace.sm),
          Text(OwnRecipeCopy.addBody, style: nest.text.bodySecondary),
          const SizedBox(height: NestSpace.md),
          NestButton(
            key: const ValueKey('own-recipes-add'),
            label: OwnRecipeCopy.addAction,
            icon: LucideIcons.plus,
            onPressed: () => _add(context),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    if (!await ensurePremium(context, feature: PremiumFeature.ownRecipes)) {
      return;
    }
    if (!context.mounted) return;
    switch (await _chooseWay(context)) {
      case RecipeAddWay.type:
        onOpenBuilder(null);
      case RecipeAddWay.link:
        onImport(RecipeImportWay.link);
      case RecipeAddWay.snap:
        onImport(RecipeImportWay.snap);
      case RecipeAddWay.pdf:
        onImportPdf();
      case null:
        break;
    }
  }

  static Future<RecipeAddWay?> _chooseWay(BuildContext context) =>
      showNestSheet<RecipeAddWay>(
        context: context,
        title: RecipeImportCopy.waysTitle,
        builder: (sheet) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (way, icon, tint, title, body) in const [
                (
                  RecipeAddWay.type,
                  LucideIcons.pencilLine,
                  NestTileTint.butter,
                  RecipeImportCopy.typeTitle,
                  RecipeImportCopy.typeBody,
                ),
                (
                  RecipeAddWay.link,
                  LucideIcons.link,
                  NestTileTint.lilac,
                  RecipeImportCopy.linkTitle,
                  RecipeImportCopy.linkBody,
                ),
                (
                  RecipeAddWay.snap,
                  LucideIcons.camera,
                  NestTileTint.basil,
                  RecipeImportCopy.snapTitle,
                  RecipeImportCopy.snapBody,
                ),
                (
                  RecipeAddWay.pdf,
                  LucideIcons.fileText,
                  NestTileTint.guava,
                  RecipeImportCopy.pdfTitle,
                  RecipeImportCopy.pdfBody,
                ),
              ])
                NestListRow(
                  key: ValueKey('recipe-add-${way.name}'),
                  title: title,
                  subtitle: body,
                  leading: NestIconTile(
                    icon: icon,
                    tint: tint,
                    size: NestSize.avatarMedium,
                  ),
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    color: NestTheme.of(sheet).colors.inkTertiary,
                  ),
                  onTap: () => Navigator.of(sheet).pop(way),
                ),
            ],
          ),
        ),
      );
}
