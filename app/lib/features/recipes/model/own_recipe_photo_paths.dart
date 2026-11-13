abstract final class OwnRecipePhotoPaths {
  static String card(String householdId, String recipeId, String photoId) =>
      '${_folder(householdId, recipeId)}/$photoId-card.jpg';

  static String hero(String householdId, String recipeId, String photoId) =>
      '${_folder(householdId, recipeId)}/$photoId-hero.jpg';

  static String? photoIdIn(String cardPath) =>
      RegExp(r'/([A-Za-z0-9_-]{8,64})-card\.jpg$')
          .firstMatch(cardPath)
          ?.group(1);

  static String _folder(String householdId, String recipeId) =>
      'households/$householdId/recipePhotos/$recipeId';
}
