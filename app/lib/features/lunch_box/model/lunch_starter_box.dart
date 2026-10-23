import 'package:flutter/foundation.dart';

import '../../family_profiles/model/allergen.dart';
import 'lunch_slot.dart';

/// A ready-made box NestPrep offers every household, at
/// `lunchStarterBoxes/{boxId}` — read-only, written by the backend. Not a
/// household's own go-to box (`LunchFavourite`, which is theirs, per child):
/// this is a starting point anybody may take, compartment by compartment,
/// into a plan. Each compartment it fills holds a recipe or a quick pick
/// from the starter library; it need not fill all five.
@immutable
final class LunchStarterBox {
  LunchStarterBox({
    required this.id,
    required this.name,
    required this.blurb,
    required this.order,
    required Map<LunchSlot, StarterBoxPick> picks,
  }) : picks = Map.unmodifiable(picks);

  /// At most this many are offered.
  static const limit = 20;

  final String id;
  final String name;
  final String blurb;

  /// Where it sits in the list, lowest first.
  final int order;
  final Map<LunchSlot, StarterBoxPick> picks;

  /// The recipes its compartments name, to read alongside it.
  Set<String> get recipeIds => {
    for (final pick in picks.values)
      if (pick case RecipeBoxPick(:final recipeId)) recipeId,
  };
}

/// What one compartment of a ready-made box holds: its name and the
/// allergen codes it carries, so it is checked against a child before it
/// goes anywhere (lunch-box ADR-0001).
@immutable
sealed class StarterBoxPick {
  const StarterBoxPick({required this.name, required this.allergens});

  final String name;
  final Set<Allergen> allergens;
}

/// A recipe NestPrep publishes (`recipes/{recipeId}`), made at home.
final class RecipeBoxPick extends StarterBoxPick {
  const RecipeBoxPick({
    required this.recipeId,
    required super.name,
    required super.allergens,
  });

  final String recipeId;
}

/// One of the starter library's items (`LunchSeedCatalogue`), bought or
/// packed as it is.
final class QuickBoxPick extends StarterBoxPick {
  const QuickBoxPick({
    required this.seedKey,
    required super.name,
    required super.allergens,
  });

  final String seedKey;
}
