import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/recipes/model/recipe.dart';
import 'package:nestprep/features/recipes/model/recipe_context.dart';
import 'package:nestprep/features/recipes/model/recipe_cuisine.dart';
import 'package:nestprep/features/recipes/model/recipe_difficulty.dart';
import 'package:nestprep/features/recipes/model/recipe_ingredient.dart';
import 'package:nestprep/features/recipes/model/recipe_photo.dart';
import 'package:nestprep/features/recipes/model/recipe_tag.dart';

/// A small catalogue in the shape recipes ADR-0003 publishes: dinner mains
/// and sides, a braai, a breakfast, a family lunch, puddings and one
/// lunch-box recipe — enough for every chip, shelf and the people scaler.
abstract final class RecipeFixtures {
  static RecipePhoto photo(String id) => RecipePhoto(
    card: 'recipes/$id/card-abc123.jpg',
    hero: 'recipes/$id/hero-abc123.jpg',
    isGenerated: true,
  );

  static Recipe meal(
    String id,
    String name, {
    required Map<RecipeContext, String> placement,
    Set<RecipeTag> tags = const {},
    List<String> dietTags = const [],
    String summary = 'A family favourite.',
    int servings = 4,
    int prepMinutes = 15,
    int cookMinutes = 30,
    Set<Allergen> allergens = const {},
  }) => Recipe(
    id: id,
    name: name,
    summary: summary,
    contexts: placement.keys.toSet(),
    placement: placement,
    allergens: allergens,
    dietTags: dietTags,
    ingredients: const [
      RecipeIngredient(name: 'Onions', quantity: 2, note: 'chopped'),
      RecipeIngredient(name: 'Salt', note: 'to taste'),
    ],
    steps: const ['Cook it.', 'Serve it.'],
    servings: servings,
    prepMinutes: prepMinutes,
    cookMinutes: cookMinutes,
    prepAhead: false,
    cuisine: RecipeCuisine.southAfrican,
    tags: tags,
    difficulty: RecipeDifficulty.easy,
    photo: photo(id),
  );

  /// Serves six as written, in two parts, with a line of every kind the
  /// scaler treats differently.
  static final bobotie = Recipe(
    id: 'bobotie',
    name: 'Bobotie',
    summary:
        'Spiced, fruity Cape Malay mince baked under a golden egg custard.',
    about:
        'Bobotie came to the Cape with the Cape Malay community and is now '
        'on Sunday tables across South Africa, with yellow rice and chutney.',
    contexts: const {RecipeContext.dinner},
    placement: const {RecipeContext.dinner: 'main'},
    allergens: const {Allergen.milk, Allergen.egg, Allergen.wheat},
    dietTags: const [],
    ingredients: const [
      RecipeIngredient(name: 'Beef mince', quantity: 1, unit: 'kg'),
      RecipeIngredient(name: 'Onions', quantity: 2, note: 'finely chopped'),
      RecipeIngredient(name: 'Curry powder', quantity: 2, unit: 'tbsp'),
      RecipeIngredient(name: 'Turmeric', quantity: 1, unit: 'tsp'),
      RecipeIngredient(name: 'Chutney', quantity: 0.5, unit: 'cup'),
      RecipeIngredient(name: 'Salt', note: 'to taste'),
      RecipeIngredient(
        name: 'Milk',
        quantity: 250,
        unit: 'ml',
        group: 'For the topping',
      ),
      RecipeIngredient(name: 'Eggs', quantity: 2, group: 'For the topping'),
      RecipeIngredient(
        name: 'Bay leaves',
        quantity: 4,
        group: 'For the topping',
      ),
    ],
    steps: const [
      'Heat the oven to 180 °C (160 °C fan).',
      'Fry the onions in a little oil until soft and golden, about 8 '
          'minutes. Add the curry powder and turmeric and cook for a minute.',
      'Add the mince and brown it, breaking it up. Stir in the chutney and '
          'season. Spoon into a baking dish.',
      'Whisk the milk and eggs, pour over the mince, lay the bay leaves on '
          'top and bake until the custard is set and golden, about 35 '
          'minutes.',
    ],
    servings: 6,
    prepMinutes: 20,
    cookMinutes: 60,
    prepAhead: true,
    prepNote: 'Make the mince the day before; add the custard to bake.',
    cuisine: RecipeCuisine.southAfrican,
    tags: const {RecipeTag.capeMalay, RecipeTag.traditional, RecipeTag.comfort},
    difficulty: RecipeDifficulty.medium,
    photo: photo('bobotie'),
  );

  static final boerewors = meal(
    'boerewors-rolls',
    'Boerewors rolls',
    summary:
        'Coiled farm sausage off the coals, in soft rolls with tomato '
        'and onion relish.',
    placement: const {RecipeContext.dinner: 'main'},
    tags: const {RecipeTag.braai, RecipeTag.kidFriendly, RecipeTag.quick},
    cookMinutes: 15,
  );

  static final sosaties = meal(
    'sosaties',
    'Sosaties',
    summary:
        'Curried lamb and apricot skewers, marinated overnight and '
        'grilled until sticky.',
    placement: const {RecipeContext.dinner: 'main'},
    tags: const {RecipeTag.braai, RecipeTag.traditional},
  );

  static final chakalaka = meal(
    'chakalaka',
    'Chakalaka',
    summary: 'A spicy relish of beans, carrots and peppers for every braai.',
    placement: const {
      RecipeContext.dinner: 'side',
      RecipeContext.lunch: 'side',
    },
    tags: const {RecipeTag.braai, RecipeTag.vegetableForward},
    dietTags: const ['vegan'],
  );

  static final malva = meal(
    'malva-pudding',
    'Malva pudding',
    placement: const {RecipeContext.dinner: 'dessert'},
    tags: const {RecipeTag.baking, RecipeTag.traditional},
    summary: 'A sticky, spongy apricot pudding soaked in a warm cream sauce.',
  );

  static final melktert = meal(
    'melktert',
    'Melktert',
    summary: 'Milk tart: a silky cinnamon custard in a crisp, buttery crust.',
    placement: const {RecipeContext.dinner: 'dessert'},
    tags: const {RecipeTag.baking, RecipeTag.festive},
  );

  static final mabele = meal(
    'mabele-porridge',
    'Mabele porridge',
    summary: 'Warm sorghum porridge with milk and a little honey.',
    placement: const {RecipeContext.breakfast: 'main'},
    tags: const {RecipeTag.budget, RecipeTag.quick},
    dietTags: const ['vegetarian'],
  );

  static final bunnyChow = meal(
    'bunny-chow',
    'Bunny chow',
    summary: 'Durban curry served in a hollowed-out half loaf of bread.',
    placement: const {
      RecipeContext.lunch: 'main',
      RecipeContext.dinner: 'main',
    },
    tags: const {RecipeTag.streetFood, RecipeTag.comfort},
  );

  static final wrap = meal(
    'chicken-mayo-wrap',
    'Chicken mayo wrap',
    summary: 'Shredded chicken and crunchy lettuce in a soft wrap.',
    placement: const {RecipeContext.lunchBox: 'main'},
    servings: 1,
  );

  static List<Recipe> get catalogue => [
    bobotie,
    boerewors,
    bunnyChow,
    chakalaka,
    wrap,
    mabele,
    malva,
    melktert,
    sosaties,
  ]..sort((a, b) => a.name.compareTo(b.name));
}
