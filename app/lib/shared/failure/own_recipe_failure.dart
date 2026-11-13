part of 'app_failure.dart';

// The first seven are the server's `OWN_RECIPE_REFUSALS`, which
// `own_recipe_contract_test.dart` reads; the rest are the phone's.
enum OwnRecipeProblem {
  householdRecipesOff,
  mealsNotShared,
  recipeLimitReached,
  notOwnRecipe,
  recipePhotoMissing,
  sourceLinkNotPublic,
  documentPageUnreadable,
  documentUnreadable,
  documentTooLong,
  documentTooLarge,
  documentPickerUnavailable,
  documentShareGone,
  recipePhotoUnreadable,
  recipePhotoTooLarge,
  recipePhotoRefused,
  recipePhotoPickerUnavailable,
}

final class OwnRecipeFailure extends AppFailure {
  const OwnRecipeFailure(this.problem);

  final OwnRecipeProblem problem;
}

// All the phone's: it reads the page itself (recipes ADR-0008).
enum RecipeImportProblem {
  pageRefused,
  pageNotFound,
  pageUnreachable,
  linkNotPublic,
  noRecipe,
}

final class RecipeImportFailure extends AppFailure {
  const RecipeImportFailure(this.problem);

  final RecipeImportProblem problem;
}
