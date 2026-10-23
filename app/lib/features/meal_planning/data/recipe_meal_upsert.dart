import '../../../shared/failure/app_failure.dart';

/// How a recipe becomes the household's meal `meals/recipe-<recipeId>`
/// (recipes ADR-0003 §6) when two phones may plan it at once.
///
/// Made in full the first time; after that only its ingredients move — the
/// one write any meals editor may make. The read that decides which can be
/// stale: another phone may make the meal between the read and the create,
/// and the rules then refuse the create, because a create over an existing
/// meal is an update that changes more than its ingredients. So a refused
/// create reads again, from the server: if the meal is there now the race
/// was lost and the ingredients are written instead; if it is not, the
/// refusal was real — somebody who may only look at meals — and it is
/// thrown as it came (`ENG-10`). An update a viewer is refused throws too.
///
/// Every callback throws an `AppFailure`, never a transport error.
Future<void> upsertRecipeMeal({
  required Future<bool> Function() exists,
  required Future<bool> Function() existsOnServer,
  required Future<void> Function() create,
  required Future<void> Function() updateIngredients,
}) async {
  if (await exists()) return updateIngredients();
  try {
    await create();
  } on PermissionDeniedFailure catch (refused) {
    final bool isThereNow;
    try {
      isThereNow = await existsOnServer();
    } on AppFailure {
      // The second read could not answer; the refusal is the truth we have.
      throw refused;
    }
    if (!isThereNow) rethrow;
    await updateIngredients();
  }
}
