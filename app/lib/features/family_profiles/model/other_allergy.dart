import 'package:freezed_annotation/freezed_annotation.dart';

import 'allergy_severity.dart';
import 'allergy_severity_converter.dart';

part 'other_allergy.freezed.dart';
part 'other_allergy.g.dart';

/// An allergy to something outside the fixed nine — kiwi, a medicine, bee
/// stings. Named in the household's own words, shown with the same warning,
/// and never machine-matched against a lunch (family-profiles ADR-0001).
@freezed
abstract class OtherAllergy with _$OtherAllergy {
  const factory OtherAllergy({
    required String name,
    @AllergySeverityConverter() required AllergySeverity severity,
    String? note,
  }) = _OtherAllergy;

  factory OtherAllergy.fromJson(Map<String, Object?> json) =>
      _$OtherAllergyFromJson(json);
}
