import 'recipe.dart';
import 'recipe_tag.dart';

/// The kind-of-dish chips over the recipes: a catalogue tag, or a diet tag
/// (recipes ADR-0003 §2, ADR-0006). In the order they are offered — the ones
/// a family reaches for first.
enum RecipeFacet {
  braai(tag: RecipeTag.braai),
  quick(tag: RecipeTag.quick),
  healthy(tag: RecipeTag.healthy),
  budget(tag: RecipeTag.budget),
  kidFriendly(tag: RecipeTag.kidFriendly),
  vegetarian(diet: Recipe.vegetarianTag),
  banting(diet: 'banting'),
  keto(diet: 'keto'),
  glutenFree(diet: 'glutenFree'),
  dairyFree(diet: 'dairyFree'),
  traditional(tag: RecipeTag.traditional),
  baking(tag: RecipeTag.baking),
  onePot(tag: RecipeTag.onePot),
  comfort(tag: RecipeTag.comfort),
  capeMalay(tag: RecipeTag.capeMalay),
  potjie(tag: RecipeTag.potjie),
  festive(tag: RecipeTag.festive),
  streetFood(tag: RecipeTag.streetFood),
  vegetableForward(tag: RecipeTag.vegetableForward);

  const RecipeFacet({this._tag, this._diet});

  final RecipeTag? _tag;
  final String? _diet;

  bool matches(Recipe recipe) => switch ((_tag, _diet)) {
    (final tag?, _) => recipe.tags.contains(tag),
    (_, Recipe.vegetarianTag) => recipe.isVegetarian,
    (_, final diet?) => recipe.dietTags.contains(diet),
    _ => false,
  };
}
