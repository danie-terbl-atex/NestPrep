import 'package:json_annotation/json_annotation.dart';

import 'allergen.dart';
import 'allergy_detail.dart';
import 'allergy_severity.dart';

/// The `allergies` map: allergen code → `{severity, note}` (family-profiles
/// ADR-0001). Keyed rather than listed so that Security Rules can check the
/// vocabulary with `keys().hasOnly(...)` and lunch-box can match a box with
/// `keys().hasAny(...)`.
///
/// Codes this build does not know are not read here — `FamilyProfile.fromJson`
/// moves them to `otherAllergies` first, so they are still shown. A value that
/// is not a map is an allergy of unknown seriousness, and reads as severe.
class AllergenMapConverter
    implements JsonConverter<Map<Allergen, AllergyDetail>, Object?> {
  const AllergenMapConverter();

  @override
  Map<Allergen, AllergyDetail> fromJson(Object? json) {
    if (json is! Map) return const {};
    return {
      for (final MapEntry(:key, :value) in json.entries)
        if (key is String && Allergen.fromCode(key) != null)
          Allergen.fromCode(key)!: _detail(value),
    };
  }

  static AllergyDetail _detail(Object? value) {
    if (value is! Map) {
      return const AllergyDetail(severity: AllergySeverity.severe);
    }
    final note = value['note'];
    return AllergyDetail.fromJson({
      'severity': value['severity'],
      'note': note is String ? note : null,
    });
  }

  @override
  Object toJson(Map<Allergen, AllergyDetail> value) => {
    for (final MapEntry(:key, :value) in value.entries)
      key.name: value.toJson(),
  };
}
