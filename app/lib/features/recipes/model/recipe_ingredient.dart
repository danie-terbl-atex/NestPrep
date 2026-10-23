import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_ingredient.freezed.dart';

/// One line of a recipe's ingredients: what, and — when the recipe says —
/// how much, in what, and a note ("ripe", "or any soft cheese"). [group] is
/// the part of the recipe it belongs to ("For the sauce"), so a long list
/// reads in parts (recipes ADR-0003 §2).
@freezed
abstract class RecipeIngredient with _$RecipeIngredient {
  const factory RecipeIngredient({
    required String name,
    num? quantity,
    String? unit,
    String? note,
    String? group,
  }) = _RecipeIngredient;
}
