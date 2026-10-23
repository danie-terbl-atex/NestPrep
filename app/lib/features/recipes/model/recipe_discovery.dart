import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import 'recipe.dart';
import 'recipe_catalogue.dart';
import 'recipe_context.dart';
import 'recipe_course.dart';
import 'recipe_filter.dart';
import 'recipe_shelf.dart';

/// What the recipes view shows for one catalogue, one filter and one day,
/// worked out once whenever any of them changes and never in a build
/// (`FE-12`).
///
/// With nothing asked it is editorial: tonight's dinner, the shelves, then
/// everything. Once something is asked it is only what matches — and an
/// empty [results] then is "nothing matches", which the view says beside the
/// controls that can change it (`FE-08`).
@immutable
final class RecipeDiscovery {
  const RecipeDiscovery._({
    required this.filter,
    required this.tonight,
    required this.shelves,
    required this.results,
  });

  factory RecipeDiscovery.of(
    RecipeCatalogue catalogue, {
    required RecipeFilter filter,
    required CalendarDate today,
  }) {
    final key = filter.key;
    final results = [
      for (final recipe in catalogue.recipes)
        if (filter.meal.matches(recipe) &&
            (filter.facet?.matches(recipe) ?? true) &&
            catalogue.hasWords(recipe, key))
          recipe,
    ];
    if (filter.isActive) {
      return RecipeDiscovery._(
        filter: filter,
        tonight: null,
        shelves: const [],
        results: results,
      );
    }
    return RecipeDiscovery._(
      filter: filter,
      tonight: tonightFrom(catalogue.recipes, today),
      shelves: [
        for (final kind in RecipeShelfKind.values)
          ?_shelf(kind, catalogue.recipes),
      ],
      results: results,
    );
  }

  final RecipeFilter filter;

  /// Tonight's suggestion, on the editorial page only.
  final Recipe? tonight;
  final List<RecipeShelf> shelves;

  /// Every recipe the filter lets through, in name order.
  final List<Recipe> results;

  /// One dinner main a day, the same all day and different tomorrow: the
  /// day's place in a fixed order of every dinner main, so the pick moves on
  /// through all of them before it comes round again. Null when there is no
  /// dinner main at all.
  static Recipe? tonightFrom(List<Recipe> recipes, CalendarDate today) {
    final mains = [
      for (final recipe in recipes)
        if (recipe.courseIn(RecipeContext.dinner) == RecipeCourse.main) recipe,
    ]..sort((a, b) => a.id.compareTo(b.id));
    if (mains.isEmpty) return null;
    return mains[_epoch.daysUntil(today) % mains.length];
  }

  static final _epoch = CalendarDate(2026, 1, 1);

  /// A shelf with fewer than two on it is not a shelf.
  static RecipeShelf? _shelf(RecipeShelfKind kind, List<Recipe> recipes) {
    final on = recipes.where(kind.matches).take(RecipeShelf.limit).toList();
    return on.length < 2 ? null : RecipeShelf(kind: kind, recipes: on);
  }
}
