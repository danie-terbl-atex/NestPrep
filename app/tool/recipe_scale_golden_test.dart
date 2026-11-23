import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/recipes/data/recipe_document.dart';
import 'package:nestprep/features/recipes/model/family_size.dart';
import 'package:nestprep/features/recipes/model/recipe.dart';
import 'package:nestprep/features/recipes/model/recipe_meal_lines.dart';
import 'package:nestprep/features/recipes/model/recipe_scale.dart';
import 'package:nestprep/features/recipes/ui/recipe_frame_share.dart';
import 'package:nestprep/shared/firestore/parsed_document.dart';

const _people = [1, 2, 4, 5, 6, 8, 12, 24, 30];
const _familySizes = [0, 1, 5, 30];

Map<String, Object?> _line(
  String name,
  Object? quantity, [
  String? unit,
  String? note,
]) => {'name': name, 'quantity': quantity, 'unit': unit, 'note': note};

final List<(String, bool, Map<String, Object?>)> _synthetic = [
  (
    'edge-units',
    false,
    {
      'status': 'published',
      'name': 'Every unit',
      'allergens': <String>[],
      'contexts': ['dinner'],
      'servings': 4,
      'prepMinutes': 10,
      'steps': ['Mix.'],
      'ingredients': [
        _line('Olive oil', 1, 'bottle'),
        _line('Olive oil, lots', 3, 'bottle'),
        _line('Chutney', 3, 'jar'),
        _line('Saffron', 0.001, 'g'),
        _line('Flour', 10000, 'g'),
        _line('Sugar', 10000, 'tsp'),
        _line('Water', 0, 'l'),
        _line('Lemons', -1),
        _line('Stock', '2', 'cup'),
        _line('Milk', 0.333, 'cup'),
        _line('Butter', 16, 'tbsp'),
        _line('Vanilla', 0.001, 'tsp'),
        _line('Bread', 0.5, 'loaf'),
        _line('Coriander', 1, 'bunch'),
        _line('Wine', 1.25, 'l'),
        _line('Yeast', 0.0004, 'kg'),
        _line('Cream', 999, 'ml'),
        _line('Rice', 1, 'pack'),
        _line('Tomatoes', 2, 'tin'),
        _line('Potatoes', 1, ' kg '),
        _line('Eggs', 0.001),
        _line('Mince', 10000),
        _line(
          'A very long ingredient name that runs well past the sixty letters a meal keeps',
          2,
          'g',
          'chopped',
        ),
        _line('Salt', null, null, 'to taste'),
      ],
    },
  ),
  (
    'edge-lunch-box',
    false,
    {
      'status': 'published',
      'name': 'Lunch-box muffins',
      'allergens': ['egg'],
      'contexts': ['lunchBox'],
      'servings': 12,
      'prepMinutes': 15,
      'steps': ['Bake.'],
      'ingredients': [_line('Flour', 250, 'g'), _line('Eggs', 2)],
    },
  ),
  (
    'edge-odd-contexts',
    false,
    {
      'status': 'published',
      'name': 'Odd contexts',
      'allergens': <String>[],
      'contexts': ['brunch', 7, 'lunch'],
      'servings': 6,
      'prepMinutes': 0,
      'steps': ['Serve.'],
      'ingredients': [_line('Bread', 1, 'loaf'), _line('Butter', 3, 'tbsp')],
    },
  ),
  (
    'edge-no-context',
    false,
    {
      'status': 'published',
      'name': 'No context',
      'allergens': <String>[],
      'servings': 1,
      'prepMinutes': 1,
      'steps': ['Eat.'],
      'ingredients': [_line('Steak', 2.5, 'kg'), _line('Olives', 0.1)],
    },
  ),
  (
    'own-0123456789abcdef0123',
    true,
    {
      'source': 'own',
      'name': 'Gran’s big pot',
      'allergens': <String>[],
      'contexts': ['breakfast'],
      'servings': 24,
      'prepMinutes': 5,
      'steps': ['Stir.'],
      'ingredients': [
        {'name': 'Oats', 'quantity': 0.25, 'unit': 'cup'},
        {'name': 'Eggs', 'quantity': 3},
        {'name': 'Honey'},
      ],
    },
  ),
];

void main() {
  test('writes the scaler golden the Functions port is held to', () {
    final files =
        Directory('../catalogue/recipes')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final recipes = [
      for (final file in files) _golden(_recipeOf(file)),
      for (final (id, household, document) in _synthetic)
        {
          ..._golden(_parsed(id, household, document)),
          'household': household,
          'document': document,
        },
    ];
    expect(recipes, isNotEmpty);
    final head = jsonEncode({'people': _people, 'familySizes': _familySizes});
    File('../functions/test/fixtures/recipe_scale_golden.json')
        .writeAsStringSync(
          '${head.substring(0, head.length - 1)},"recipes":[\n'
          '${recipes.map(jsonEncode).join(',\n')}\n]}\n',
        );
  });
}

Recipe _recipeOf(File file) {
  final data = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return _parsed(data['id']! as String, false, {
    ...data,
    'status': RecipeDocument.published,
  });
}

Recipe _parsed(String id, bool household, Map<String, Object?> data) {
  final parsed = household
      ? RecipeDocument.parseHousehold(id, data)
      : RecipeDocument.parse(id, data);
  return switch (parsed) {
    ValidDocument(:final value) => value,
    RejectedDocument(:final reason) => throw StateError('$id: $reason'),
  };
}

Map<String, Object?> _golden(Recipe recipe) => {
  'id': recipe.id,
  'startingPeople': {
    for (final size in _familySizes) '$size': startingPeopleFor(recipe, size),
  },
  'scaled': {
    for (final people in _people)
      '$people': _scaled(
        recipe,
        RecipeScale(people: people, servings: recipe.servings),
      ),
  },
};

Map<String, Object?> _scaled(Recipe recipe, RecipeScale scale) => {
  'amounts': frameAmounts(recipe.ingredients, scale),
  'mealLines': [
    for (final line in recipeMealLines(recipe, scale))
      [line.name, line.amount, line.unitCode],
  ],
};
