import 'package:flutter/foundation.dart';

import 'recipe_context.dart';
import 'recipe_course.dart';
import 'recipe_ingredient.dart';
import 'recipe_origin.dart';
import 'recipe_photo_cuts.dart';

/// What the builder opens filled with: a read link, photo or PDF. Nothing is
/// stored until the member taps Save (recipes ADR-0008), except a recipe of
/// several taken from one PDF, which is saved as it is (recipes ADR-0009). The
/// builder clips anything past `OwnRecipeLimits`, and says so.
@immutable
final class RecipeDraft {
  const RecipeDraft({
    this.name = '',
    this.summary = '',
    this.notes,
    this.placement = const {},
    this.ingredients = const [],
    this.steps = const [],
    this.servings,
    this.prepMinutes,
    this.cookMinutes,
    this.candidateImageUrls = const [],
    this.photos = const [],
    this.origin = RecipeOrigin.typed,
    this.sourceUrl,
    this.sourceName,
    this.cutShort = false,
  });

  final String name;
  final String summary;
  final String? notes;
  final Map<RecipeContext, RecipeCourse> placement;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final int? servings;
  final int? prepMinutes;
  final int? cookMinutes;
  final List<String> candidateImageUrls;
  final List<RecipePhotoCuts> photos;
  final RecipeOrigin origin;
  final String? sourceUrl;
  final String? sourceName;
  final bool cutShort;

  RecipeDraft withSource({required String url, required String name}) =>
      _copy(sourceUrl: url, sourceName: name);

  RecipeDraft withPhotos(List<RecipePhotoCuts> photos) => _copy(photos: photos);

  RecipeDraft _copy({
    String? sourceUrl,
    String? sourceName,
    List<RecipePhotoCuts>? photos,
  }) => RecipeDraft(
    name: name,
    summary: summary,
    notes: notes,
    placement: placement,
    ingredients: ingredients,
    steps: steps,
    servings: servings,
    prepMinutes: prepMinutes,
    cookMinutes: cookMinutes,
    candidateImageUrls: candidateImageUrls,
    photos: photos ?? this.photos,
    origin: origin,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    sourceName: sourceName ?? this.sourceName,
    cutShort: cutShort,
  );
}
