import 'package:flutter/foundation.dart';

import '../../family_profiles/model/allergen.dart';
import '../../recipes/model/recipe.dart';
import '../../recipes/model/recipe_context.dart';
import '../../recipes/model/recipe_ingredient.dart';

/// One ingredient of a drafted dish: what it is, how much for one box when
/// the model said, in a meal-planning unit code, and the words to search
/// Checkers with (lunch-box ADR-0021 §1).
@immutable
final class DishIngredient {
  const DishIngredient({
    required this.name,
    required this.searchTerm,
    this.quantity,
    this.unitCode,
  });

  final String name;
  final String searchTerm;
  final num? quantity;
  final String? unitCode;
}

/// The dish a main idea is (lunch-box ADR-0021): drafted by the model in the
/// ideas call, bounded and allergen-coded by the server. On *Use it* it is
/// saved as the household's recipe (recipes ADR-0002) and becomes the
/// lunch item, named after the dish.
@immutable
final class DishDraft {
  DishDraft({
    required this.name,
    required this.summary,
    required List<DishIngredient> ingredients,
    required List<String> steps,
    required this.prepMinutes,
    required this.prepAhead,
    required Set<Allergen> allergens,
    this.prepNote,
  }) : ingredients = List.unmodifiable(ingredients),
       steps = List.unmodifiable(steps),
       allergens = Set.unmodifiable(allergens);

  final String name;
  final String summary;
  final List<DishIngredient> ingredients;
  final List<String> steps;
  final int prepMinutes;
  final bool prepAhead;
  final String? prepNote;

  /// The codes the server read in the dish's words.
  final Set<Allergen> allergens;

  /// The draft as the callable sent it, or null when it is not a whole one —
  /// a dish missing a name, its ingredients or its method is no dish
  /// (`ENG-09`). An allergen code this build does not know rejects it: never
  /// read as safe.
  static DishDraft? fromWire(Object? data) {
    if (data
        case {
          'name': final String name,
          'ingredients': final List<Object?> lines,
          'steps': final List<Object?> steps,
          'prepMinutes': final int prepMinutes,
          'allergens': final List<Object?> codes,
        }
        when name.trim().isNotEmpty && lines.isNotEmpty && steps.isNotEmpty) {
      final ingredients = [for (final line in lines) ?_ingredient(line)];
      final allergens = {
        for (final code in codes)
          if (code is String) Allergen.fromCode(code),
      };
      if (ingredients.length != lines.length || allergens.contains(null)) {
        return null;
      }
      return DishDraft(
        name: name.trim(),
        summary: switch (data['summary']) {
          final String summary => summary.trim(),
          _ => '',
        },
        ingredients: ingredients,
        steps: steps.whereType<String>().toList(),
        prepMinutes: prepMinutes,
        prepAhead: data['prepAhead'] == true,
        prepNote: switch (data['prepNote']) {
          final String note when note.trim().isNotEmpty => note.trim(),
          _ => null,
        },
        allergens: allergens.nonNulls.toSet(),
      );
    }
    return null;
  }

  static DishIngredient? _ingredient(Object? data) => switch (data) {
    {'name': final String name, 'searchTerm': final String searchTerm}
        when name.trim().isNotEmpty =>
      DishIngredient(
        name: name.trim(),
        searchTerm: searchTerm.trim().isEmpty ? name.trim() : searchTerm.trim(),
        quantity: switch (data['quantity']) {
          final num quantity when quantity > 0 => quantity,
          _ => null,
        },
        unitCode: switch (data['unit']) {
          final String unit when unit.isNotEmpty => unit,
          _ => null,
        },
      ),
    _ => null,
  };

  /// The dish as a recipe the sheet can show before anything is saved — one
  /// box's worth, drafted for this family.
  Recipe toRecipe() => Recipe(
    id: '',
    name: name,
    summary: summary,
    contexts: const {RecipeContext.lunchBox},
    placement: const {RecipeContext.lunchBox: 'main'},
    allergens: allergens,
    dietTags: const [],
    ingredients: [
      for (final line in ingredients)
        RecipeIngredient(
          name: line.name,
          quantity: line.quantity,
          unit: line.unitCode,
        ),
    ],
    steps: steps,
    servings: 1,
    prepMinutes: prepMinutes,
    prepAhead: prepAhead,
    prepNote: prepNote,
    isAiDrafted: true,
  );

  /// What `saveLunchRecipes` takes for this dish (recipes ADR-0002): its
  /// words — each ingredient's search words too, read for codes (lunch-box
  /// ADR-0023) — and [alsoContains], the codes the chosen products' labels
  /// add.
  Map<String, Object?> toSaveWire({required Set<Allergen> alsoContains}) => {
    'name': name,
    'summary': summary,
    'ingredients': [
      for (final line in ingredients)
        {
          'name': line.name,
          'quantity': line.quantity,
          'unit': line.unitCode,
          'searchTerm': line.searchTerm,
        },
    ],
    'steps': steps,
    'prepMinutes': prepMinutes,
    'prepAhead': prepAhead,
    'prepNote': prepNote,
    'alsoContains': [
      for (final allergen in Allergen.values)
        if (alsoContains.contains(allergen)) allergen.name,
    ],
  };
}
