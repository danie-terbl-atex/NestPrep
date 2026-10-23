import 'dart:async';

import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/lunch_box/data/lunch_starter_box_repository.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_starter_box.dart';
import 'package:nestprep/features/recipes/model/recipe.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_ingredient.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// The ready-made boxes on offer, decided by the test: [boxes], or
/// [failWith]; [gate] holds the answer back so a test sees it loading.
final class FakeLunchStarterBoxRepository implements LunchStarterBoxRepository {
  FakeLunchStarterBoxRepository([this.boxes = const []]);

  List<LunchStarterBox> boxes;
  AppFailure? failWith;
  Completer<void>? gate;
  var fetches = 0;

  @override
  Future<List<LunchStarterBox>> fetchPublished() async {
    fetches++;
    await gate?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    return boxes;
  }
}

/// Two recipes and three ready-made boxes over `LunchFixtures`' children —
/// Lwazi, peanut-allergic at a nut-free school, and Ayanda. The ids are the
/// tests' own, not the backend's.
abstract final class StarterBoxFixtures {
  static const muffinId = 'test-oat-muffin';
  static const wrapId = 'test-hummus-wrap';

  static Recipe get muffin => const Recipe(
    id: muffinId,
    name: 'Oat and banana muffin',
    summary: 'Soft, not too sweet, and freezes well.',
    contexts: {RecipeContext.lunchBox},
    placement: {RecipeContext.lunchBox: 'treat'},
    allergens: {Allergen.wheat, Allergen.egg, Allergen.milk},
    dietTags: ['vegetarian'],
    ingredients: [
      RecipeIngredient(name: 'ripe bananas', quantity: 2),
      RecipeIngredient(name: 'rolled oats', quantity: 1.5, unit: 'cups'),
      RecipeIngredient(name: 'egg', quantity: 1, note: 'large'),
    ],
    steps: ['Mash the bananas.', 'Stir everything together.', 'Bake 20 min.'],
    servings: 12,
    prepMinutes: 30,
    prepAhead: true,
    prepNote: 'Bake a dozen on Sunday and freeze half.',
  );

  static Recipe get wrap => const Recipe(
    id: wrapId,
    name: 'Hummus veggie wrap',
    summary: '',
    contexts: {RecipeContext.lunchBox},
    placement: {RecipeContext.lunchBox: 'main'},
    allergens: {Allergen.wheat, Allergen.sesame},
    dietTags: [],
    ingredients: [RecipeIngredient(name: 'wrap')],
    steps: ['Spread, fill, roll.'],
    servings: 1,
    prepMinutes: 5,
    prepAhead: false,
  );

  /// A wrap, apple slices and a muffin for Friday.
  static LunchStarterBox get classic => LunchStarterBox(
    id: 'test-box-classic',
    name: 'The classic',
    blurb: 'A wrap, fruit and a Friday muffin.',
    order: 1,
    picks: {
      LunchSlot.main: const RecipeBoxPick(
        recipeId: wrapId,
        name: 'Hummus veggie wrap',
        allergens: {Allergen.wheat},
      ),
      LunchSlot.fruit: const QuickBoxPick(
        seedKey: 'apple',
        name: 'Apple slices',
        allergens: {},
      ),
      LunchSlot.treat: const RecipeBoxPick(
        recipeId: muffinId,
        name: 'Oat and banana muffin',
        allergens: {Allergen.wheat, Allergen.egg},
      ),
    },
  );

  /// Cheese sandwich and grapes — no treat.
  static LunchStarterBox get crunch => LunchStarterBox(
    id: 'test-box-crunch',
    name: 'Crunch time',
    blurb: '',
    order: 2,
    picks: {
      LunchSlot.main: const QuickBoxPick(
        seedKey: 'cheese-rolls',
        name: 'Cheese rolls',
        allergens: {Allergen.wheat, Allergen.milk},
      ),
      LunchSlot.fruit: const QuickBoxPick(
        seedKey: 'grapes',
        name: 'Grapes',
        allergens: {},
      ),
    },
  );

  /// Trail mix: nuts, so never for Lwazi.
  static LunchStarterBox get trail => LunchStarterBox(
    id: 'test-box-trail',
    name: 'Trail day',
    blurb: 'For the hungry ones.',
    order: 3,
    picks: {
      LunchSlot.snack: const QuickBoxPick(
        seedKey: 'trail-mix',
        name: 'Trail mix',
        allergens: {Allergen.peanut, Allergen.treeNut},
      ),
    },
  );

  static List<LunchStarterBox> get all => [classic, crunch, trail];
  static List<Recipe> get recipes => [muffin, wrap];
}
