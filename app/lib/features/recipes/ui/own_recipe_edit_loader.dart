import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe.dart';
import '../state/recipe_catalogue_controller.dart';
import 'own_recipe_guard.dart';

class OwnRecipeEditLoader extends StatefulWidget {
  const OwnRecipeEditLoader({
    required this.recipeId,
    required this.onBack,
    required this.builder,
    super.key,
  });

  final String recipeId;
  final VoidCallback onBack;
  final Widget Function(Recipe recipe) builder;

  @override
  State<OwnRecipeEditLoader> createState() => _OwnRecipeEditLoaderState();
}

class _OwnRecipeEditLoaderState extends State<OwnRecipeEditLoader> {
  // Kept from the first read, so a save arriving through the listener mid-edit
  // never replaces what somebody is typing.
  Recipe? _recipe;

  @override
  Widget build(BuildContext context) {
    final catalogue = context.watch<RecipeCatalogueController>();
    final found = catalogue.recipe(widget.recipeId);
    if (_recipe == null && found != null && found.isOwn) _recipe = found;
    if (_recipe case final recipe?) return widget.builder(recipe);
    return OwnRecipeNotice(
      onBack: widget.onBack,
      child: switch (catalogue.catalogue) {
        AsyncLoading() => const NestSkeleton.rows(count: 6),
        AsyncFailure(:final failure) => NestErrorView(
          message: AppCopy.failure(failure),
          retryLabel: AppCopy.retry,
          onRetry: catalogue.retry,
        ),
        AsyncData() => const NestEmptyView(
          icon: LucideIcons.bookX,
          title: RecipeCopy.missingTitle,
          message: RecipeCopy.pageMissingMessage,
        ),
      },
    );
  }
}
