import 'package:freezed_annotation/freezed_annotation.dart';

import 'allergy_severity.dart';
import 'allergy_severity_converter.dart';

part 'allergy_detail.freezed.dart';
part 'allergy_detail.g.dart';

/// What the household knows about one of the fixed allergens for one person:
/// how serious it is, and anything a carer should read before feeding them.
@freezed
abstract class AllergyDetail with _$AllergyDetail {
  const factory AllergyDetail({
    @AllergySeverityConverter() required AllergySeverity severity,
    String? note,
  }) = _AllergyDetail;

  factory AllergyDetail.fromJson(Map<String, Object?> json) =>
      _$AllergyDetailFromJson(json);
}
