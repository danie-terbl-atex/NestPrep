import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/meal_ingredient.dart';
import 'package:nestprep/features/recipes/model/recipe_link.dart';

void main() {
  const ingredients = [MealIngredient(name: 'Eggs')];

  test('an own recipe\'s meal writes householdRecipeId and never recipeId', () {
    const ownId = 'own-0123456789abcdef0123';
    final meal = Meal.ofRecipe(
      link: const HouseholdRecipeLink(ownId),
      name: 'Bobotie',
      ingredients: ingredients,
      addedBy: 'm-sam',
    );
    final json = meal.toJson();
    expect(meal.id, 'recipe-$ownId');
    expect(json['householdRecipeId'], ownId);
    expect(json.containsKey('recipeId'), isFalse);
    expect(meal.recipeLink, const HouseholdRecipeLink(ownId));
  });

  test('a catalogue recipe\'s meal is as it always was', () {
    final meal = Meal.ofRecipe(
      link: const CatalogueRecipeLink('bobotie'),
      name: 'Bobotie',
      ingredients: ingredients,
      addedBy: 'm-sam',
    );
    final json = meal.toJson();
    expect(meal.id, 'recipe-bobotie');
    expect(json['recipeId'], 'bobotie');
    expect(json.containsKey('householdRecipeId'), isFalse);
    expect(meal.recipeLink, const CatalogueRecipeLink('bobotie'));
  });

  test(
    'a typed meal carries neither, and reads a meal an older build wrote',
    () {
      expect(
        Meal.named(id: 'm1', name: 'Pizza', addedBy: 'm-sam').toJson().keys,
        isNot(anyOf(contains('recipeId'), contains('householdRecipeId'))),
      );
      final old = Meal.fromJson(const {
        'id': 'recipe-bobotie',
        'name': 'Bobotie',
        'nameKey': 'bobotie',
        'addedBy': 'm-sam',
        'recipeId': 'bobotie',
      });
      expect(old.recipeLink, const CatalogueRecipeLink('bobotie'));
    },
  );

  test('a meal whose own recipe was deleted has no link left', () {
    final unlinked = Meal.fromJson(const {
      'id': 'recipe-own-0123456789abcdef0123',
      'name': 'Bobotie',
      'nameKey': 'bobotie',
      'addedBy': 'm-sam',
    });
    expect(unlinked.recipeLink, isNull);
  });
}
