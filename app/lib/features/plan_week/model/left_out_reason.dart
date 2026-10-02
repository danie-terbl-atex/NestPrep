import 'package:flutter/foundation.dart';

import '../../family_profiles/model/allergen.dart';

/// Why NestPrep left an idea or a shop's product out (lunch-box ADR-0012) —
/// said on screen, so a parent sees what was decided and for whom.
enum LeftOutKind {
  /// The shop has none at the moment.
  outOfStock,

  /// Priced by the kilogram; a lunch plan counts boxes, not grams.
  soldByWeight,

  /// It names an allergen this child is allergic to.
  allergy,

  /// It names a nut, and nuts are ruled out for this child by their diet or
  /// school rather than an allergy.
  nutRule,

  /// It names one of this child's own written allergies.
  otherAllergy,

  /// It names something this child does not like.
  dislike,

  /// The shop says nothing about what is in it, and this child has
  /// allergies — so it cannot be called safe.
  unknownContents,
}

@immutable
final class LeftOutReason {
  const LeftOutReason(this.kind, {this.childId, this.allergen, this.word});

  final LeftOutKind kind;

  /// Whose rule it was; null when it is the product's own (stock, weight).
  final String? childId;

  /// For [LeftOutKind.allergy] and [LeftOutKind.nutRule].
  final Allergen? allergen;

  /// The written allergy or the dislike, for those two kinds.
  final String? word;

  /// A reason that keeps it from every child, not only one.
  bool get isForEverybody => childId == null;

  @override
  bool operator ==(Object other) =>
      other is LeftOutReason &&
      other.kind == kind &&
      other.childId == childId &&
      other.allergen == allergen &&
      other.word == word;

  @override
  int get hashCode => Object.hash(kind, childId, allergen, word);
}
