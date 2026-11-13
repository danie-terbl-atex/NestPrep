import '../../../shared/failure/app_failure.dart';
import 'recipe_context.dart';
import 'recipe_course.dart';
import 'recipe_draft.dart';
import 'recipe_ingredient.dart';
import 'recipe_origin.dart';

final class RecipeDraftReading {
  const RecipeDraftReading({required this.draft, required this.callsLeft});

  final RecipeDraft? draft;
  final int callsLeft;

  factory RecipeDraftReading.fromWire(Object? data) {
    if (data is! Map) throw _unreadable;
    final isRecipe = data['isRecipe'];
    final callsLeft = data['callsLeft'];
    if (isRecipe is! bool || callsLeft is! num) throw _unreadable;
    if (!isRecipe) {
      return RecipeDraftReading(draft: null, callsLeft: callsLeft.toInt());
    }
    final recipe = data['recipe'];
    if (recipe is! Map) throw _unreadable;
    final name = recipe['name'];
    if (name is! String || name.trim().isEmpty) throw _unreadable;
    return RecipeDraftReading(
      callsLeft: callsLeft.toInt(),
      draft: RecipeDraft(
        name: name,
        summary: _text(recipe['summary']) ?? '',
        notes: _text(recipe['notes']),
        placement: _placement(recipe['placement']),
        ingredients: _ingredients(recipe['ingredients']),
        steps: [
          for (final Object? step in _list(recipe['steps']))
            if (step is String) step,
        ],
        servings: _whole(recipe['servings']),
        prepMinutes: _whole(recipe['prepMinutes']),
        cookMinutes: _whole(recipe['cookMinutes']),
        candidateImageUrls: [
          for (final Object? url in _list(data['imageUrls']))
            if (url is String) url,
        ],
        origin: RecipeOrigin.fromName(_text(recipe['origin'])),
        sourceUrl: _text(recipe['sourceUrl']),
        sourceName: _text(recipe['sourceName']),
        cutShort: recipe['cutShort'] == true,
      ),
    );
  }

  static const _unreadable = AiFailure(AiProblem.aiUnreadable);

  static String? _text(Object? value) => value is String ? value : null;

  static int? _whole(Object? value) => value is num ? value.round() : null;

  static List<Object?> _list(Object? value) => value is List ? value : const [];

  static Map<RecipeContext, RecipeCourse> _placement(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final MapEntry(:key, value: named) in value.entries)
        if (key is String)
          ?RecipeContext.fromName(key): ?RecipeCourse.fromName(_text(named)),
    };
  }

  static List<RecipeIngredient> _ingredients(Object? value) => [
    for (final Object? line in _list(value))
      if (line case {'name': final String name} when name.trim().isNotEmpty)
        RecipeIngredient(
          name: name,
          quantity: switch (line['quantity']) {
            final num quantity => quantity,
            _ => null,
          },
          unit: _text(line['unit']),
          note: _text(line['note']),
          group: _text(line['group']),
        ),
  ];
}
