import '../../list_scan/model/list_photo.dart';
import '../model/recipe_draft_reading.dart';
import '../model/recipe_page.dart';

abstract interface class RecipeDrafter {
  Future<RecipeDraftReading> fromPage({
    required String householdId,
    required RecipePage page,
  });

  Future<RecipeDraftReading> fromPhoto({
    required String householdId,
    required ListPhoto photo,
  });
}
