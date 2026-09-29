import 'package:flutter/foundation.dart';

import 'allergen.dart';
import 'allergy_detail.dart';
import 'allergy_severity.dart';
import 'other_allergy.dart';

/// One allergy, whichever of the two ways it is stored — the shape every
/// reader wants (a screen, lunch-box, a nanny-hub card), so none of them has to
/// know that the fixed nine and the free-text rest live in different maps
/// (family-profiles ADR-0001).
@immutable
class Allergy {
  Allergy.known(Allergen this.allergen, AllergyDetail detail)
    : otherId = null,
      otherName = null,
      severity = detail.severity,
      note = detail.note;

  Allergy.other(String this.otherId, OtherAllergy other)
    : allergen = null,
      otherName = other.name,
      severity = other.severity,
      note = other.note;

  /// Set for one of the fixed nine; null for a free-text allergy.
  final Allergen? allergen;

  /// The key of a free-text allergy in `otherAllergies`; null otherwise.
  final String? otherId;

  /// What the household called a free-text allergy; null for the fixed nine,
  /// whose names are copy.
  final String? otherName;

  final AllergySeverity severity;
  final String? note;

  /// Stable across rebuilds, for a list key (`FE-11`).
  String get key => allergen?.name ?? 'other:$otherId';

  /// Most dangerous first, then by name so the order does not shuffle.
  static int bySeverity(Allergy a, Allergy b) {
    final severity = b.severity.index.compareTo(a.severity.index);
    if (severity != 0) return severity;
    return a.key.compareTo(b.key);
  }

  @override
  bool operator ==(Object other) =>
      other is Allergy &&
      other.allergen == allergen &&
      other.otherId == otherId &&
      other.otherName == otherName &&
      other.severity == severity &&
      other.note == note;

  @override
  int get hashCode => Object.hash(allergen, otherId, otherName, severity, note);
}
