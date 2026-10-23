import '../../../shared/firestore/document_fields.dart';
import '../../../shared/firestore/parsed_document.dart';
import '../../family_profiles/model/allergen.dart';
import '../model/recipe.dart';
import '../model/recipe_context.dart';
import '../model/recipe_cuisine.dart';
import '../model/recipe_difficulty.dart';
import '../model/recipe_ingredient.dart';
import '../model/recipe_photo.dart';
import '../model/recipe_tag.dart';

/// `recipes/{recipeId}` and `households/{id}/recipes/{recipeId}` as this
/// build reads them (`ENG-09`, `BE-10`). What a person relies on — the name,
/// what is in it, how to make it — must be there and well formed, or the
/// recipe is left out; a retired catalogue recipe is left out too. Everything
/// else falls back quietly: an unknown context, tag or course, a missing
/// summary, photo or cooking time never costs a family the recipe — and an
/// older document carries none of what recipes ADR-0003 added.
abstract final class RecipeDocument {
  static const published = 'published';
  static const aiSource = 'ai';

  /// One of NestPrep's catalogue recipes: only a published one is read.
  static ParsedDocument<Recipe> parse(String id, Map<String, Object?> data) {
    if (DocumentFields.text(data['name']) == null) {
      return const RejectedDocument('name');
    }
    if (data['status'] != published) return const RejectedDocument('status');
    return _recipe(id, data);
  }

  /// One of the household's own (recipes ADR-0002): immutable, so it has no
  /// status to retire it by.
  static ParsedDocument<Recipe> parseHousehold(
    String id,
    Map<String, Object?> data,
  ) => _recipe(id, data);

  static ParsedDocument<Recipe> _recipe(String id, Map<String, Object?> data) {
    final name = DocumentFields.text(data['name']);
    if (name == null) return const RejectedDocument('name');
    final allergens = Allergen.parseCodes(data['allergens']);
    if (allergens == null) return const RejectedDocument('allergens');
    final ingredients = _ingredients(data['ingredients']);
    if (ingredients == null) return const RejectedDocument('ingredients');
    final steps = DocumentFields.texts(data['steps']);
    if (steps == null) return const RejectedDocument('steps');
    final servings = DocumentFields.whole(data['servings']);
    if (servings == null || servings < 1) {
      return const RejectedDocument('servings');
    }
    final prepMinutes = DocumentFields.whole(data['prepMinutes']);
    if (prepMinutes == null || prepMinutes < 0) {
      return const RejectedDocument('prepMinutes');
    }
    return ValidDocument(
      Recipe(
        id: id,
        name: name,
        summary: DocumentFields.text(data['summary']) ?? '',
        contexts: _contexts(data['contexts']),
        placement: _placement(data['placement']),
        allergens: allergens,
        dietTags: DocumentFields.texts(data['dietTags']) ?? const [],
        ingredients: ingredients,
        steps: steps,
        servings: servings,
        prepMinutes: prepMinutes,
        prepAhead: data['prepAhead'] == true,
        prepNote: DocumentFields.text(data['prepNote']),
        isAiDrafted: data['source'] == aiSource,
        about: DocumentFields.text(data['about']),
        cuisine: RecipeCuisine.fromName(DocumentFields.text(data['cuisine'])),
        tags: _tags(data['tags']),
        cookMinutes: switch (DocumentFields.whole(data['cookMinutes'])) {
          final minutes? when minutes > 0 => minutes,
          _ => 0,
        },
        difficulty: RecipeDifficulty.fromName(
          DocumentFields.text(data['difficulty']),
        ),
        photo: _photo(data['photo']),
      ),
    );
  }

  static Set<RecipeTag> _tags(Object? value) => switch (value) {
    final List<Object?> names => {
      for (final name in names)
        if (name is String) ?RecipeTag.fromName(name),
    },
    _ => const {},
  };

  /// Both pictures, or none: a recipe with one size only would show a
  /// placeholder in one place and a photo in the other.
  static RecipePhoto? _photo(Object? value) {
    if (value is! Map<Object?, Object?>) return null;
    final card = DocumentFields.text(value['card']);
    final hero = DocumentFields.text(value['hero']);
    if (card == null || hero == null) return null;
    return RecipePhoto(
      card: card,
      hero: hero,
      credit: DocumentFields.text(value['credit']),
      licence: DocumentFields.text(value['licence']),
      sourceUrl: DocumentFields.text(value['sourceUrl']),
      isGenerated: value['generated'] == true,
    );
  }

  static Set<RecipeContext> _contexts(Object? value) => switch (value) {
    final List<Object?> names => {
      for (final name in names)
        if (name is String) ?RecipeContext.fromName(name),
    },
    _ => const {},
  };

  static Map<RecipeContext, String> _placement(Object? value) =>
      switch (value) {
        final Map<Object?, Object?> places => {
          for (final MapEntry(:key, :value) in places.entries)
            if ((key, value) case (final String name, final String place))
              ?RecipeContext.fromName(name): place,
        },
        _ => const {},
      };

  /// Every line, or null when any is not an ingredient — a recipe missing a
  /// line could be missing the one a child reacts to.
  static List<RecipeIngredient>? _ingredients(Object? value) {
    if (value is! List<Object?>) return null;
    final lines = [for (final line in value) ?_ingredient(line)];
    return lines.length == value.length ? lines : null;
  }

  static RecipeIngredient? _ingredient(Object? value) {
    if (value is! Map<Object?, Object?>) return null;
    final name = DocumentFields.text(value['name']);
    if (name == null) return null;
    return RecipeIngredient(
      name: name,
      quantity: switch (value['quantity']) {
        final num quantity when quantity > 0 => quantity,
        _ => null,
      },
      unit: DocumentFields.text(value['unit']),
      note: DocumentFields.text(value['note']),
      group: DocumentFields.text(value['group']),
    );
  }
}
