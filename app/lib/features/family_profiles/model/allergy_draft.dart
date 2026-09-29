import 'package:flutter/foundation.dart';

import 'allergen.dart';
import 'allergy_detail.dart';
import 'allergy_severity.dart';
import 'other_allergy.dart';

/// What the allergy sheet collected: one of the fixed allergens, or a name in
/// the household's own words — never both — with how serious it is.
@immutable
class AllergyDraft {
  const AllergyDraft.known({
    required Allergen this.allergen,
    required this.severity,
    this.note,
  }) : otherName = null;

  const AllergyDraft.other({
    required String this.otherName,
    required this.severity,
    this.note,
  }) : allergen = null;

  final Allergen? allergen;
  final String? otherName;
  final AllergySeverity severity;
  final String? note;

  AllergyDetail get detail => AllergyDetail(severity: severity, note: note);

  OtherAllergy get asOther => OtherAllergy(
    name: otherName ?? allergen?.name ?? '',
    severity: severity,
    note: note,
  );

  @override
  bool operator ==(Object other) =>
      other is AllergyDraft &&
      other.allergen == allergen &&
      other.otherName == otherName &&
      other.severity == severity &&
      other.note == note;

  @override
  int get hashCode => Object.hash(allergen, otherName, severity, note);
}
