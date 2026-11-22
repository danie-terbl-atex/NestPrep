import '../model/recipe_draft_reading.dart';
import '../model/recipe_page.dart';
import '../model/recipe_snap.dart';

abstract interface class RecipeDrafter {
  Future<RecipeDraftReading> fromPage({
    required String householdId,
    required RecipePage page,
  });

  /// Every photo of one recipe, read together as one call.
  Future<RecipeDraftReading> fromPhotos({
    required String householdId,
    required List<RecipeSnap> photos,
  });
}
