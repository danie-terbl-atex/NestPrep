import 'package:json_annotation/json_annotation.dart';

import 'dietary_flag.dart';

/// The `diet` list, stored as codes in the enum's order so the same set always
/// writes the same list. A code this build does not know is skipped rather
/// than failing the whole profile (`BE-10`).
class DietaryFlagsConverter
    implements JsonConverter<Set<DietaryFlag>, Object?> {
  const DietaryFlagsConverter();

  @override
  Set<DietaryFlag> fromJson(Object? json) {
    if (json is! List) return const {};
    return {
      for (final code in json)
        if (code is String && DietaryFlag.fromCode(code) != null)
          DietaryFlag.fromCode(code)!,
    };
  }

  @override
  Object toJson(Set<DietaryFlag> value) => [
    for (final flag in DietaryFlag.values)
      if (value.contains(flag)) flag.name,
  ];
}
