import 'package:flutter/foundation.dart';

import '../../family_profiles/model/allergen.dart';
import '../../family_profiles/model/food_rules.dart';

/// Why one thing should not, or might not, go in one child's box
/// (lunch-box ADR-0001). The first two are safety: the rules refuse a box that
/// has them. The last is a preference: suggestions leave it out, and a parent
/// who picks it anyway sees it named.
@immutable
sealed class LunchConcern {
  const LunchConcern();

  /// Whether the rules refuse a box with this in it.
  bool get isUnsafe;
}

/// The child is allergic to something in it.
final class AllergenConcern extends LunchConcern {
  const AllergenConcern(this.allergen);

  final Allergen allergen;

  @override
  bool get isUnsafe => true;

  @override
  bool operator ==(Object other) =>
      other is AllergenConcern && other.allergen == allergen;

  @override
  int get hashCode => allergen.hashCode;
}

/// It has nuts, and nuts are ruled out for this child by their diet or their
/// school — not by an allergy to this nut, which [AllergenConcern] says.
final class NutRuleConcern extends LunchConcern {
  const NutRuleConcern(this.reasons);

  final Set<NutFreeReason> reasons;

  @override
  bool get isUnsafe => true;

  @override
  bool operator ==(Object other) =>
      other is NutRuleConcern && setEquals(other.reasons, reasons);

  @override
  int get hashCode => Object.hashAllUnordered(reasons);
}

/// The child has said they do not like it.
final class DislikeConcern extends LunchConcern {
  const DislikeConcern(this.dislike);

  /// The dislike as the family wrote it.
  final String dislike;

  @override
  bool get isUnsafe => false;

  @override
  bool operator ==(Object other) =>
      other is DislikeConcern && other.dislike == dislike;

  @override
  int get hashCode => dislike.hashCode;
}
