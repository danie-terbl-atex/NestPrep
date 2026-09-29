import 'package:json_annotation/json_annotation.dart';

import 'allergy_severity.dart';

/// A severity, stored as its name. Anything unreadable is severe — see
/// `AllergySeverity.fromCode`.
class AllergySeverityConverter
    implements JsonConverter<AllergySeverity, Object?> {
  const AllergySeverityConverter();

  @override
  AllergySeverity fromJson(Object? json) => AllergySeverity.fromCode(json);

  @override
  Object toJson(AllergySeverity value) => value.name;
}
