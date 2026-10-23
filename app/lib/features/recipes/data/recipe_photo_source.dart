import 'dart:typed_data';

/// The bytes of a recipe's picture, by its Storage object path (recipes
/// ADR-0003 §4). A path's content never changes — its name carries a hash —
/// so each is fetched once and kept. Null when it cannot be had: the picture
/// is decoration, and a recipe without one still cooks.
abstract interface class RecipePhotoSource {
  Future<Uint8List?> photo(String path);
}
