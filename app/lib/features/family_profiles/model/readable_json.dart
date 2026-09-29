/// The one place a stored profile or health document is read without trusting
/// its shape.
///
/// Security Rules can bound a map or a list but cannot look inside one
/// (family-profiles ADR-0001), and every family screen waits on one listener
/// over every profile — so a single malformed entry must cost that entry's
/// detail, never the whole family (`BE-10`). The birthday and colour
/// converters fall back for the same reason. Everything here leans one way:
/// an allergy or a medicine is kept, under a name that says what it is, rather
/// than dropped.
library;

import 'allergen.dart';

/// A stored profile, reshaped into exactly what the generated reader expects.
Map<String, Object?> readableProfileJson(Map<String, Object?> json) {
  final allergies = _stringKeyed(json['allergies']);
  final unknown = {
    for (final MapEntry(:key, :value) in allergies.entries)
      if (Allergen.fromCode(key) == null) key: value,
  };
  return {
    ...json,
    'isChild': json['isChild'] is bool ? json['isChild'] : false,
    'likes': _stringsIn(json['likes']),
    'dislikes': _stringsIn(json['dislikes']),
    'allergies': {
      for (final MapEntry(:key, :value) in allergies.entries)
        if (!unknown.containsKey(key)) key: value,
    },
    // An allergen a newer build added is shown as free text under its code.
    'otherAllergies': {
      for (final MapEntry(:key, :value) in _stringKeyed(
        json['otherAllergies'],
      ).entries)
        key: _namedEntry(key, value),
      for (final MapEntry(:key, :value) in unknown.entries)
        unrecognisedAllergenKey(key): _namedEntry(key, value),
    },
    for (final field in ['schoolId', 'grade', 'clothingSize', 'shoeSize'])
      field: _stringAt(json, field),
  };
}

/// A stored health document, reshaped the same way.
Map<String, Object?> readableHealthJson(Map<String, Object?> json) => {
  ...json,
  'medications': {
    for (final MapEntry(:key, :value) in _stringKeyed(
      json['medications'],
    ).entries)
      key: _medication(key, value),
  },
};

/// Where an allergen code this build does not know is kept in
/// `otherAllergies`.
String unrecognisedAllergenKey(String code) => 'unrecognised-$code';

Map<String, Object?> _namedEntry(String key, Object? value) {
  final entry = _stringKeyed(value);
  return {
    'name': _stringAt(entry, 'name') ?? key,
    'severity': entry['severity'],
    'note': _stringAt(entry, 'note'),
  };
}

Map<String, Object?> _medication(String key, Object? value) {
  final entry = _stringKeyed(value);
  final times = entry['times'];
  return {
    'name': _stringAt(entry, 'name') ?? key,
    'dose': _stringAt(entry, 'dose'),
    'note': _stringAt(entry, 'note'),
    'times': times is List
        ? [
            for (final time in times.whereType<int>())
              if (time >= 0 && time < _minutesInADay) time,
          ]
        : const <int>[],
  };
}

const _minutesInADay = 24 * 60;

Map<String, Object?> _stringKeyed(Object? json) => json is Map
    ? {
        for (final MapEntry(:key, :value) in json.entries)
          if (key is String) key: value,
      }
    : const {};

List<String> _stringsIn(Object? json) =>
    json is List ? json.whereType<String>().toList() : const [];

String? _stringAt(Map<String, Object?> json, String key) {
  final value = json[key];
  return value is String ? value : null;
}
