import 'package:flutter/foundation.dart';

import '../../../shared/text/normalised_name.dart';
import 'recipe.dart';
import 'recipe_facet.dart';
import 'recipe_meal_filter.dart';

/// NestPrep's published recipes as the Meals tab holds them, with what is
/// asked of them on every keystroke worked out once per read (`FE-12`): each
/// one by id, the words a search looks in, and which chips would find
/// anything at all — a chip that can only say "no matches" is not offered.
@immutable
final class RecipeCatalogue {
  RecipeCatalogue(this.recipes)
    : byId = {for (final recipe in recipes) recipe.id: recipe},
      _searchText = {
        for (final recipe in recipes) recipe.id: _searchTextOf(recipe),
      },
      meals = [
        for (final meal in RecipeMealFilter.values)
          if (meal == RecipeMealFilter.all || recipes.any(meal.matches)) meal,
      ],
      facets = [
        for (final facet in RecipeFacet.values)
          if (recipes.any(facet.matches)) facet,
      ];

  /// In name order, as the repository reads them.
  final List<Recipe> recipes;
  final Map<String, Recipe> byId;
  final Map<String, String> _searchText;

  /// The meal chips worth offering, always starting with all of them.
  final List<RecipeMealFilter> meals;

  /// The kind-of-dish chips worth offering.
  final List<RecipeFacet> facets;

  bool get isEmpty => recipes.isEmpty;

  /// Whether [recipe] has every word of [key] somewhere in its name, its
  /// summary or its ingredients — "chicken pie" finds a pie with chicken in.
  bool hasWords(Recipe recipe, String key) {
    if (key.isEmpty) return true;
    final text = _searchText[recipe.id] ?? '';
    return key.split(' ').every(text.contains);
  }

  static String _searchTextOf(Recipe recipe) => normalisedName(
    [
      recipe.name,
      recipe.summary,
      for (final line in recipe.ingredients) line.name,
    ].join(' '),
  );
}
