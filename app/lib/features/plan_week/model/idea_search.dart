import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import 'checked_product.dart';
import 'ingredient_find.dart';
import 'lunch_idea.dart';

/// Where one idea's search at the shop is.
enum IdeaSearchStatus { waiting, searching, done, failed }

/// One idea looked for at the shop (lunch-box ADR-0012, step 3): what the
/// shop found, which products NestPrep kept for which children, and every one
/// it left out with why — or the failure, said in words. A dish (ADR-0021)
/// is looked for ingredient by ingredient, in [ingredients].
@immutable
final class IdeaSearch {
  IdeaSearch({
    required this.idea,
    required this.status,
    List<CheckedProduct> found = const [],
    List<IngredientFind> ingredients = const [],
    this.failure,
  }) : found = List.unmodifiable(found),
       ingredients = List.unmodifiable(ingredients);

  IdeaSearch.waiting(LunchIdea idea)
    : this(idea: idea, status: IdeaSearchStatus.waiting);

  final LunchIdea idea;
  final IdeaSearchStatus status;

  /// Everything the shop answered, judged, in the order to offer it: the
  /// shop's for a search, the best kept first for a shelf.
  final List<CheckedProduct> found;

  /// A dish's ingredients as the shop answered each; empty for a product.
  final List<IngredientFind> ingredients;
  final AppFailure? failure;

  String get ideaId => idea.id;

  bool get isDish => idea.dish != null;

  /// Whether the week can be built from this: a product idea that kept
  /// something, or a dish some child can have whole (lunch-box ADR-0023).
  bool get hasKept => isDish ? dishChildIds.isNotEmpty : kept.isNotEmpty;

  /// The children a dish can go to: taken in order, each only while every
  /// ingredient still has a product all of them may have — the server's rule
  /// (lunch-box ADR-0023 §2). An ingredient the shop had nothing for means
  /// nobody. Empty for a product idea.
  List<String> get dishChildIds {
    if (!isDish || ingredients.isEmpty) return const [];
    final children = <String>[];
    for (final childId in idea.childIds) {
      final trying = [...children, childId];
      if (ingredients.every((find) => find.keptForAll(trying).isNotEmpty)) {
        children.add(childId);
      }
    }
    return children;
  }

  /// The product a dish's ingredient was bought as, by its id.
  CheckedProduct? ingredientProduct(String productId) =>
      [for (final ingredient in ingredients) ...ingredient.found]
          .where((product) => product.productId == productId)
          .firstOrNull;

  List<CheckedProduct> get kept => [
    for (final product in found)
      if (product.isKept) product,
  ];

  List<CheckedProduct> get leftOut => [
    for (final product in found)
      if (!product.isKept) product,
  ];

  bool get isSettled =>
      status == IdeaSearchStatus.done || status == IdeaSearchStatus.failed;

  /// The products that may go to [childId], in the shop's order.
  List<CheckedProduct> keptFor(String childId) => [
    for (final product in kept)
      if (product.childIds.contains(childId)) product,
  ];

  CheckedProduct? keptProduct(String productId) =>
      kept.where((product) => product.productId == productId).firstOrNull;

  IdeaSearch searching() =>
      IdeaSearch(idea: idea, status: IdeaSearchStatus.searching);

  IdeaSearch answered(List<CheckedProduct> found) =>
      IdeaSearch(idea: idea, status: IdeaSearchStatus.done, found: found);

  IdeaSearch answeredDish(List<IngredientFind> ingredients) => IdeaSearch(
    idea: idea,
    status: IdeaSearchStatus.done,
    ingredients: ingredients,
  );

  IdeaSearch failedWith(AppFailure failure) =>
      IdeaSearch(idea: idea, status: IdeaSearchStatus.failed, failure: failure);
}
