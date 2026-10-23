import 'recipe.dart';
import 'recipe_tag.dart';

/// The kind-of-dish chips over the recipes: a catalogue tag, or vegetarian,
/// which is a diet tag rather than one of the catalogue's (recipes ADR-0003
/// §2). In the order they are offered — the ones a family reaches for first.
enum RecipeFacet {
  braai(RecipeTag.braai),
  quick(RecipeTag.quick),
  budget(RecipeTag.budget),
  kidFriendly(RecipeTag.kidFriendly),
  vegetarian(null),
  traditional(RecipeTag.traditional),
  baking(RecipeTag.baking),
  onePot(RecipeTag.onePot),
  comfort(RecipeTag.comfort),
  capeMalay(RecipeTag.capeMalay),
  potjie(RecipeTag.potjie),
  festive(RecipeTag.festive),
  streetFood(RecipeTag.streetFood),
  vegetableForward(RecipeTag.vegetableForward);

  const RecipeFacet(this._tag);

  final RecipeTag? _tag;

  bool matches(Recipe recipe) => switch (_tag) {
    final tag? => recipe.tags.contains(tag),
    null => recipe.isVegetarian,
  };
}
