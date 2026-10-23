import 'dart:io';
import 'dart:typed_data';

import 'package:nestprep/features/recipes/data/recipe_photo_source.dart';

/// Recipe pictures answered by the test: none at all by default — every
/// recipe shows its placeholder — or the one fixture photo for every path,
/// for a design-review picture of the real thing.
final class FakeRecipePhotoSource implements RecipePhotoSource {
  FakeRecipePhotoSource({this.bytes});

  /// A small, real photo of bobotie (generated, as the catalogue's are), for
  /// the presses — `test/fixtures/recipe_photo.jpg`.
  factory FakeRecipePhotoSource.fixture() => FakeRecipePhotoSource(
    bytes: File('test/fixtures/recipe_photo.jpg').readAsBytesSync(),
  );

  final Uint8List? bytes;
  final asked = <String>[];

  @override
  Future<Uint8List?> photo(String path) async {
    asked.add(path);
    return bytes;
  }
}
