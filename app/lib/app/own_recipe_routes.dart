import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/household/model/household_view.dart';
import '../features/list_scan/data/list_photo_picker.dart';
import '../features/meal_planning/data/meal_repository.dart';
import '../features/photo_frames/model/shared_pdf.dart';
import '../features/recipes/data/own_recipe_photo_store.dart';
import '../features/recipes/data/own_recipe_repository.dart';
import '../features/recipes/data/recipe_document_reader.dart';
import '../features/recipes/data/recipe_drafter.dart';
import '../features/recipes/data/recipe_image_fetcher.dart';
import '../features/recipes/data/recipe_page_reader.dart';
import '../features/recipes/data/recipe_pdf.dart';
import '../features/recipes/data/recipe_photo_picker.dart';
import '../features/recipes/data/recipe_photo_source.dart';
import '../features/recipes/data/shared_pdf_inbox.dart';
import '../features/recipes/model/family_size.dart';
import '../features/recipes/model/recipe.dart';
import '../features/recipes/model/recipe_draft.dart';
import '../features/recipes/state/own_recipe_importer.dart';
import '../features/recipes/state/recipe_builder_controller.dart';
import '../features/recipes/state/recipe_document_controller.dart';
import '../features/recipes/state/recipe_image_picks.dart';
import '../features/recipes/state/recipe_import_controller.dart';
import '../features/recipes/state/recipe_photo_intake.dart';
import '../features/recipes/ui/own_recipe_edit_loader.dart';
import '../features/recipes/ui/own_recipe_guard.dart';
import '../features/recipes/ui/recipe_builder_screen.dart';
import '../features/recipes/ui/recipe_document_screen.dart';
import '../features/recipes/ui/recipe_import_screen.dart';
import 'household_route.dart';
import 'meals_route.dart';

/// `new`, `import` and `import-pdf` must stay ahead of `:recipeId` in the
/// route table, or they would open as recipes of those names.
List<GoRoute> ownRecipeRoutes() => [
  GoRoute(
    path: MealsRoute.importPdfPath,
    builder: (context, state) {
      final householdId = HouseholdRoute.idFrom(state);
      void back() => _leave(context, householdId);
      return OwnRecipeGuard(
        onBack: back,
        child: ChangeNotifierProvider(
          create: (context) {
            final controller = RecipeDocumentController(
              picker: context.read<RecipePdfPicker>(),
              inbox: context.read<SharedPdfInbox>(),
              rasterizer: context.read<PdfRasterizer>(),
              reader: context.read<RecipeDocumentReader>(),
              importer: OwnRecipeImporter(
                ownRecipes: context.read<OwnRecipeRepository>(),
                photoStore: context.read<OwnRecipePhotoStore>(),
                householdId: householdId,
                viewerUid: context.read<HouseholdView>().viewerUid,
              ),
              photoIntake: const RecipePhotoIntake(),
              householdId: householdId,
            );
            if (state.extra case final SharedPdf shared) {
              unawaited(controller.receive(shared.token));
            }
            return controller;
          },
          child: RecipeDocumentScreen(
            onBack: back,
            onOpenBuilder: (draft) => context.pushReplacement(
              MealsRoute.newRecipePathFor(householdId),
              extra: draft,
            ),
            onFinish: (draft) => context.push(
              MealsRoute.newRecipePathFor(householdId),
              extra: draft,
            ),
            onSeeRecipes: () => context.go(MealsRoute.pathFor(householdId)),
          ),
        ),
      );
    },
  ),
  GoRoute(
    path: MealsRoute.importRecipePath,
    builder: (context, state) {
      final householdId = HouseholdRoute.idFrom(state);
      return OwnRecipeGuard(
        onBack: () => _leave(context, householdId),
        child: ChangeNotifierProvider(
          create: (context) => RecipeImportController(
            pageReader: context.read<RecipePageReader>(),
            drafter: context.read<RecipeDrafter>(),
            photoPicker: context.read<ListPhotoPicker>(),
            householdId: householdId,
            way: MealsRoute.importWayFrom(state),
          ),
          child: RecipeImportScreen(
            sharedLink: switch (state.extra) {
              final String link => link,
              _ => null,
            },
            onOpenBuilder: (draft) => context.pushReplacement(
              MealsRoute.newRecipePathFor(householdId),
              extra: draft,
            ),
          ),
        ),
      );
    },
  ),
  GoRoute(
    path: MealsRoute.newRecipePath,
    builder: (context, state) {
      final householdId = HouseholdRoute.idFrom(state);
      void back() => _leave(context, householdId);
      return OwnRecipeGuard(
        onBack: back,
        child: _OwnRecipeBuilder(
          householdId: householdId,
          draft: switch (state.extra) {
            final RecipeDraft draft => draft,
            _ => null,
          },
          onDone: back,
        ),
      );
    },
  ),
  GoRoute(
    path: MealsRoute.editRecipePath,
    builder: (context, state) {
      final householdId = HouseholdRoute.idFrom(state);
      void back() => _leave(context, householdId);
      return OwnRecipeGuard(
        onBack: back,
        child: OwnRecipeEditLoader(
          recipeId: MealsRoute.recipeIdFrom(state),
          onBack: back,
          builder: (recipe) => _OwnRecipeBuilder(
            householdId: householdId,
            editing: recipe,
            onDone: back,
          ),
        ),
      );
    },
  ),
];

void _leave(BuildContext context, String householdId) => context.canPop()
    ? context.pop()
    : context.go(MealsRoute.pathFor(householdId));

class _OwnRecipeBuilder extends StatelessWidget {
  const _OwnRecipeBuilder({
    required this.householdId,
    required this.onDone,
    this.editing,
    this.draft,
  });

  final String householdId;
  final VoidCallback onDone;
  final Recipe? editing;
  final RecipeDraft? draft;

  @override
  Widget build(BuildContext context) {
    final view = context.read<HouseholdView>();
    final screen = RecipeBuilderScreen(onDone: onDone);
    final imageUrls = draft?.candidateImageUrls ?? const <String>[];
    return ChangeNotifierProvider(
      create: (context) => RecipeBuilderController(
        ownRecipes: context.read<OwnRecipeRepository>(),
        photoStore: context.read<OwnRecipePhotoStore>(),
        photoPicker: context.read<RecipePhotoPicker>(),
        photoIntake: const RecipePhotoIntake(),
        photoSource: context.read<RecipePhotoSource>(),
        mealRepository: context.read<MealRepository>(),
        householdId: householdId,
        viewerUid: view.viewerUid,
        familySize: familySizeOf(view),
        editing: editing,
        draft: draft,
      ),
      child: imageUrls.isEmpty
          ? screen
          : ChangeNotifierProvider(
              create: (context) => RecipeImagePicks(
                builder: context.read<RecipeBuilderController>(),
                fetcher: context.read<RecipeImageFetcher>(),
                intake: const RecipePhotoIntake(),
                urls: imageUrls,
                credit: draft?.sourceName,
                sourceUrl: draft?.sourceUrl,
              ),
              lazy: false,
              child: screen,
            ),
    );
  }
}
