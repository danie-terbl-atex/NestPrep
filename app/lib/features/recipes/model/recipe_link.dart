import 'package:flutter/foundation.dart';

/// Which recipe something opens (recipes ADR-0002): one NestPrep publishes
/// (`recipes/{id}`) or one of the household's own, drafted by *Plan my week*
/// (`households/{householdId}/recipes/{id}`). A lunch item carries one or
/// neither, in two separate fields, so the kind is never guessed from an id.
@immutable
sealed class RecipeLink {
  const RecipeLink(this.recipeId);

  /// The link two stored fields make, or null when neither is set. A
  /// household link wins only when it is the one set — the rules never let
  /// an item carry both.
  static RecipeLink? of({String? recipeId, String? householdRecipeId}) =>
      switch ((recipeId, householdRecipeId)) {
        (final id?, _) when id.isNotEmpty => CatalogueRecipeLink(id),
        (_, final id?) when id.isNotEmpty => HouseholdRecipeLink(id),
        _ => null,
      };

  final String recipeId;

  @override
  bool operator ==(Object other) =>
      other is RecipeLink &&
      other.runtimeType == runtimeType &&
      other.recipeId == recipeId;

  @override
  int get hashCode => Object.hash(runtimeType, recipeId);
}

/// A recipe from NestPrep's catalogue (recipes ADR-0001).
final class CatalogueRecipeLink extends RecipeLink {
  const CatalogueRecipeLink(super.recipeId);
}

/// A recipe the household saved from *Plan my week* (recipes ADR-0002).
final class HouseholdRecipeLink extends RecipeLink {
  const HouseholdRecipeLink(super.recipeId);
}
