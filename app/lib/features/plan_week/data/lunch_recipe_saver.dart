import 'package:flutter/foundation.dart';

import '../../family_profiles/model/allergen.dart';
import '../model/dish_draft.dart';

/// A dish to save, and the codes the products bought for it add.
typedef DishToSave = ({DishDraft draft, Set<Allergen> alsoContains});

/// One saved household recipe: its id, and the allergen codes the server
/// gave it — a lunch item linked to it must carry at least these.
@immutable
final class SavedLunchRecipe {
  const SavedLunchRecipe({required this.id, required this.allergens});

  final String id;
  final Set<Allergen> allergens;
}

/// Saves the dishes a parent uses as the household's own recipes
/// (`saveLunchRecipes`, recipes ADR-0002), before their items are written.
/// Behind an interface so a test decides what comes back (`FE-20`). Saving
/// the same dish twice saves it once.
abstract interface class LunchRecipeSaver {
  /// The saved recipes in the order of [dishes].
  Future<List<SavedLunchRecipe>> save({
    required String householdId,
    required List<DishToSave> dishes,
  });
}
