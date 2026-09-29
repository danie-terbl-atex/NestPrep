import 'package:flutter/foundation.dart';

/// One shopping-list line of a new dinner idea: a name and, where the model
/// knew it, how much ("1 kg", "2").
@immutable
final class IdeaIngredient {
  const IdeaIngredient({required this.name, this.quantity});

  final String name;
  final String? quantity;

  static const nameLimit = 40;
  static const quantityLimit = 20;

  static IdeaIngredient? fromWire(Object? data) {
    if (data is! Map) return null;
    final name = data['name'];
    final quantity = data['quantity'];
    if (name is! String) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > nameLimit) return null;
    final amount = quantity is String ? quantity.trim() : '';
    return IdeaIngredient(
      name: trimmed,
      quantity: amount.isEmpty || amount.length > quantityLimit ? null : amount,
    );
  }
}

/// A dinner nobody in the household has cooked yet, proposed by the model
/// with what it needs (lunch-box ADR-0011). It becomes a meal in the library
/// only when the plan is used, and its ingredients reach the grocery list only
/// when a parent says so.
@immutable
final class DinnerIdea {
  const DinnerIdea({required this.name, required this.ingredients});

  final String name;
  final List<IdeaIngredient> ingredients;

  static const nameLimit = 60;

  static DinnerIdea? fromWire(Object? data) {
    if (data is! Map) return null;
    final name = data['name'];
    final lines = data['ingredients'];
    if (name is! String || lines is! List) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > nameLimit) return null;
    final ingredients = [
      for (final line in lines) ?IdeaIngredient.fromWire(line),
    ];
    if (ingredients.isEmpty) return null;
    return DinnerIdea(
      name: trimmed,
      ingredients: List.unmodifiable(ingredients),
    );
  }
}
