import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/recipes/model/recipe_ingredient.dart';
import 'package:nestprep/features/recipes/model/recipe_scale.dart';
import 'package:nestprep/features/recipes/model/scaled_ingredients.dart';
import 'package:nestprep/features/recipes/ui/recipe_frame_share.dart';
import 'package:nestprep/features/recipes/ui/scaled_ingredient_text.dart';

import '../../../support/recipe_fixtures.dart';

void main() {
  final bobotie = RecipeFixtures.bobotie;
  final serverAmount = RegExp(r'^[0-9A-Za-z ./]*$');

  test('one amount per line, in the recipe order, as the page shows it', () {
    final scale = RecipeScale(people: 3, servings: bobotie.servings);
    final amounts = frameAmounts(bobotie.ingredients, scale);

    expect(amounts, hasLength(bobotie.ingredients.length));
    for (final (index, line) in bobotie.ingredients.indexed) {
      final shown = ScaledIngredientText.of(scaleIngredient(line, scale))
          .amount;
      expect(amounts[index], line.quantity == null ? isNull : shown);
    }
    expect(amounts.first, '500 g');
    expect(amounts[1], '1');
    expect(amounts[4], '1/4 cup');
  });

  test('a line with no quantity is null, never an empty string', () {
    final scale = RecipeScale.asWritten(bobotie.servings);
    final amounts = frameAmounts(bobotie.ingredients, scale);

    final salt = bobotie.ingredients.indexWhere((line) => line.name == 'Salt');
    expect(amounts[salt], isNull);
    expect(
      [
        for (final (index, amount) in amounts.indexed)
          if (amount == null) index,
      ],
      [salt],
    );
  });

  test('the groups never reorder the lines', () {
    const lines = [
      RecipeIngredient(name: 'Milk', quantity: 1, unit: 'cup', group: 'B'),
      RecipeIngredient(name: 'Flour', quantity: 2, unit: 'cup', group: 'A'),
      RecipeIngredient(name: 'Sugar', quantity: 3, unit: 'tbsp', group: 'B'),
    ];
    final amounts = frameAmounts(lines, RecipeScale(people: 2, servings: 2));

    expect(amounts, ['1 cup', '2 cups', '3 tbsp']);
  });

  test('every catalogue amount at every people count is one the server '
      'takes', () {
    for (final recipe in RecipeFixtures.catalogue) {
      for (
        var people = RecipeScale.minPeople;
        people <= RecipeScale.maxPeople;
        people++
      ) {
        final scale = RecipeScale(people: people, servings: recipe.servings);
        for (final amount in frameAmounts(recipe.ingredients, scale)) {
          if (amount == null) continue;
          expect(amount, matches(serverAmount), reason: recipe.id);
          expect(amount.length, lessThanOrEqualTo(24), reason: recipe.id);
        }
      }
    }
  });

  test('the share carries the recipe, its people and its card photo', () {
    final scale = RecipeScale(people: 4, servings: bobotie.servings);
    final share = recipeFrameShare(bobotie, scale);

    expect(share.recipeId, bobotie.id);
    expect(share.name, bobotie.name);
    expect(share.people, 4);
    expect(share.amounts, frameAmounts(bobotie.ingredients, scale));
    expect(share.cardPhotoPath, bobotie.photo!.card);
  });
}
