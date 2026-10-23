import 'package:flutter/foundation.dart';

import 'kitchen_fraction.dart';

/// How many people a recipe is being cooked for against how many it is
/// written for (recipes ADR-0003 §5). Scaling is presentation arithmetic on
/// data the phone already has: every quantity is multiplied by [factor], and
/// nothing about the choice is stored except what adding it to the week
/// writes.
@immutable
final class RecipeScale {
  RecipeScale({required int people, required this.servings})
    : people = people.clamp(minPeople, maxPeople);

  /// The recipe as written.
  RecipeScale.asWritten(this.servings)
    : people = servings.clamp(minPeople, maxPeople);

  /// The range the people control offers — the schema's own bounds on
  /// `servings` (the recipe authoring guide).
  static const minPeople = 1;
  static const maxPeople = 24;

  final int people;

  /// What the quantities as written make; never below one, which the parser
  /// guarantees.
  final int servings;

  double get factor => people / servings;

  bool get isAsWritten => people == servings;

  /// How far the recipe is scaled, as a cook reads it: `1 1/2`, `2/3`, `2` —
  /// or, when no kitchen fraction is close, one decimal (`1.2`).
  String get factorText {
    final kitchen = KitchenFraction.round(factor);
    if ((kitchen - factor).abs() < 0.02) return KitchenFraction.text(kitchen);
    return factor.toStringAsFixed(1);
  }

  bool get canAdd => people < maxPeople;
  bool get canRemove => people > minPeople;

  RecipeScale withPeople(int people) =>
      RecipeScale(people: people, servings: servings);

  @override
  bool operator ==(Object other) =>
      other is RecipeScale &&
      other.people == people &&
      other.servings == servings;

  @override
  int get hashCode => Object.hash(people, servings);
}
