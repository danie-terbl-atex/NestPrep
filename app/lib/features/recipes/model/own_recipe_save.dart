import 'package:flutter/foundation.dart';

import '../../family_profiles/model/allergen.dart';
import 'recipe_context.dart';
import 'recipe_course.dart';
import 'recipe_ingredient.dart';
import 'recipe_origin.dart';

@immutable
final class OwnRecipePhotoRef {
  const OwnRecipePhotoRef({required this.photoId, this.credit, this.sourceUrl});

  final String photoId;
  final String? credit;
  final String? sourceUrl;
}

@immutable
final class OwnRecipeSave {
  const OwnRecipeSave({
    required this.name,
    required this.summary,
    required this.notes,
    required this.placement,
    required this.ingredients,
    required this.steps,
    required this.servings,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.origin,
    required this.sourceUrl,
    required this.sourceName,
    required this.alsoContains,
    required this.photo,
    required this.gallery,
  });

  final String name;
  final String summary;
  final String? notes;
  final Map<RecipeContext, RecipeCourse> placement;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final int servings;
  final int prepMinutes;
  final int cookMinutes;
  final RecipeOrigin origin;
  final String? sourceUrl;
  final String? sourceName;
  final Set<Allergen> alsoContains;
  final OwnRecipePhotoRef? photo;
  final List<OwnRecipePhotoRef> gallery;
}
