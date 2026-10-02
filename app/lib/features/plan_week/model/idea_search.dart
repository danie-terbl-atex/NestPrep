import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import 'checked_product.dart';
import 'lunch_idea.dart';

/// Where one idea's search at the shop is.
enum IdeaSearchStatus { waiting, searching, done, failed }

/// One idea looked for at the shop (lunch-box ADR-0012, step 3): what the
/// shop found, which products NestPrep kept for which children, and every one
/// it left out with why — or the failure, said in words.
@immutable
final class IdeaSearch {
  IdeaSearch({
    required this.idea,
    required this.status,
    List<CheckedProduct> found = const [],
    this.failure,
  }) : found = List.unmodifiable(found);

  IdeaSearch.waiting(LunchIdea idea)
    : this(idea: idea, status: IdeaSearchStatus.waiting);

  final LunchIdea idea;
  final IdeaSearchStatus status;

  /// Everything the shop answered, judged, in the order to offer it: the
  /// shop's for a search, the best kept first for a shelf.
  final List<CheckedProduct> found;
  final AppFailure? failure;

  String get ideaId => idea.id;

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

  IdeaSearch failedWith(AppFailure failure) =>
      IdeaSearch(idea: idea, status: IdeaSearchStatus.failed, failure: failure);
}
