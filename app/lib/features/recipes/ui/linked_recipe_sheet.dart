import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../data/recipe_repository.dart';
import '../model/recipe.dart';
import '../model/recipe_link.dart';
import '../state/linked_recipe_controller.dart';
import 'recipe_sheet.dart';

/// *How to make it* for something that names a recipe by [link] — a lunch
/// item on the board or in the library (lunch-box ADR-0021 §8). The sheet
/// opens at once under [title], the item's own name, and reads the recipe
/// while it shows: loading, not there any more, failed with a retry, or the
/// recipe itself — the same `RecipeSheet` every recipe opens in.
Future<void> showLinkedRecipeSheet(
  BuildContext context, {
  required String householdId,
  required RecipeLink link,
  required String title,
}) {
  final recipes = context.read<RecipeRepository>();
  return showNestSheet<void>(
    context: context,
    title: title,
    builder: (_) => ChangeNotifierProvider(
      create: (_) => LinkedRecipeController(
        recipes: recipes,
        householdId: householdId,
        link: link,
      ),
      child: const LinkedRecipeView(),
    ),
  );
}

class LinkedRecipeView extends StatelessWidget {
  const LinkedRecipeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LinkedRecipeController>();
    return NestAsyncView<Recipe?>(
      state: controller.state,
      isEmpty: (recipe) => recipe == null,
      loadingRows: 5,
      onRetry: controller.retry,
      emptyBuilder: (_) => const NestEmptyView(
        icon: LucideIcons.bookX,
        title: RecipeCopy.missingTitle,
        message: RecipeCopy.missingMessage,
      ),
      dataBuilder: (_, recipe) => RecipeSheet(recipe: recipe!),
    );
  }
}
