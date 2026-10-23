import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_photo.freezed.dart';

/// A catalogue recipe's picture (recipes ADR-0003 §4): two Storage objects of
/// the same photo — [card] about 640 px wide for lists, [hero] about 1200 px
/// for the recipe page (`FE-18`) — whose names carry a content hash, so a
/// path never changes what it shows.
///
/// Either openly licensed, with who took it and under what licence, or
/// [isGenerated] by NestPrep's image model and captioned as an illustration.
@freezed
abstract class RecipePhoto with _$RecipePhoto {
  const factory RecipePhoto({
    required String card,
    required String hero,
    String? credit,
    String? licence,
    String? sourceUrl,
    @Default(false) bool isGenerated,
  }) = _RecipePhoto;
}
