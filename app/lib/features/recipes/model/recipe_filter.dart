import 'package:flutter/foundation.dart';

import '../../../shared/text/normalised_name.dart';
import 'recipe_facet.dart';
import 'recipe_meal_filter.dart';

/// What somebody has asked the recipes for: words typed, a meal, a kind of
/// dish. Nothing asked is the editorial page — tonight's pick and the
/// shelves; anything asked is the list of what matches.
@immutable
final class RecipeFilter {
  const RecipeFilter({
    this.query = '',
    this.meal = RecipeMealFilter.all,
    this.facet,
  });

  final String query;
  final RecipeMealFilter meal;
  final RecipeFacet? facet;

  /// [query] as it is compared — the normaliser the meal library uses.
  String get key => normalisedName(query);

  bool get isActive =>
      key.isNotEmpty || meal != RecipeMealFilter.all || facet != null;

  RecipeFilter withQuery(String query) =>
      RecipeFilter(query: query, meal: meal, facet: facet);

  RecipeFilter withMeal(RecipeMealFilter meal) =>
      RecipeFilter(query: query, meal: meal, facet: facet);

  /// A second tap on the chosen facet clears it.
  RecipeFilter toggling(RecipeFacet facet) => RecipeFilter(
    query: query,
    meal: meal,
    facet: this.facet == facet ? null : facet,
  );

  @override
  bool operator ==(Object other) =>
      other is RecipeFilter &&
      other.query == query &&
      other.meal == meal &&
      other.facet == facet;

  @override
  int get hashCode => Object.hash(query, meal, facet);
}
