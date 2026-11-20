import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../model/recipe_draft.dart';
import '../model/recipe_import_way.dart';
import 'own_recipe_access.dart';

enum RecipeAddWay { type, link, snap, pdf }

/// The way into adding a household's own recipe, in the Recipes app bar.
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
    return NestIconButton(
      key: const ValueKey('own-recipes-add'),
      icon: LucideIcons.plus,
      label: OwnRecipeCopy.addTitle,
      onPressed: () => _add(context),
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
