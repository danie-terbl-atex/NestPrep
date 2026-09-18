import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/model_fixtures.dart';

/// What a repository hands to `set` must be something Firestore can store.
///
/// This is not the same check as "it round-trips". `jsonEncode` calls `toJson()`
/// on any object it meets, so a nested model left as an object still encodes
/// correctly to a JSON string — and `json_serializable` relies on exactly that,
/// emitting `'recurrence': instance.recurrence` unless `explicit_to_json` is on.
///
/// **Firestore never calls `toJson()`.** It walks the map and refuses any value
/// that is not one of its own types. So a nested model is a write that fails at
/// runtime, on a device, against the real backend — while the analyzer, the
/// generator and every controller test stay perfectly happy.
///
/// That is what was wrong here. `Task`, `Routine` and `HouseholdEvent` each nest
/// a `RecurrenceRule`. **Creating** one went through `toJson()`; **updating** one
/// hand-built its map with `recurrence?.toJson()`. Update worked. Create could
/// never have worked, and recurrence is a v1 capability (foundation ADR-0005).
/// `build.yaml` now sets `explicit_to_json`, and this is what holds it there.
void main() {
  /// Every type `cloud_firestore` accepts as a field value. A `DateTime` is
  /// converted by the SDK; `Timestamp`, `GeoPoint`, `Blob`, `DocumentReference`
  /// and `FieldValue` are its own.
  String? firstUnstorable(Object? value, String path) {
    if (value == null ||
        value is num ||
        value is bool ||
        value is String ||
        value is DateTime ||
        value is Timestamp ||
        value is GeoPoint ||
        value is Blob ||
        value is DocumentReference ||
        value is FieldValue) {
      return null;
    }
    if (value is List) {
      for (var index = 0; index < value.length; index++) {
        final found = firstUnstorable(value[index], '$path[$index]');
        if (found != null) return found;
      }
      return null;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        if (entry.key is! String) {
          return '$path: a map key is ${entry.key.runtimeType}, not a String';
        }
        final found = firstUnstorable(entry.value, '$path.${entry.key}');
        if (found != null) return found;
      }
      return null;
    }
    return '$path: ${value.runtimeType} is not a type Firestore can store — '
        'a nested model needs `.toJson()`, which means `explicit_to_json`';
  }

  group('every stored document', () {
    for (final fixture in modelFixtures()) {
      test('${fixture.label} is something Firestore can store', () {
        expect(firstUnstorable(fixture.toJson(), fixture.label), isNull);
      });
    }
  });

  group('the check itself', () {
    test('accepts the types Firestore takes', () {
      expect(
        firstUnstorable({
          'n': 1,
          'd': 1.5,
          'b': true,
          's': 'x',
          'nil': null,
          'when': fixtureTimestamp,
          'list': [1, 'two', null],
          'nested': {
            'deep': ['a'],
          },
        }, 'doc'),
        isNull,
      );
    });

    test('names the field and the type when it finds one it cannot store', () {
      final found = firstUnstorable({
        'ok': 'yes',
        'rule': fixtureRecurrence,
      }, 'doc');

      expect(found, contains('doc.rule'));
      expect(found, contains('explicit_to_json'));
    });

    test('finds one buried in a list inside a map', () {
      expect(
        firstUnstorable({
          'outer': {
            'inner': [1, fixtureRecurrence],
          },
        }, 'doc'),
        contains('doc.outer.inner[1]'),
      );
    });

    test('refuses a non-string map key, which Firestore also refuses', () {
      expect(
        firstUnstorable({
          'outer': {1: 'x'},
        }, 'doc'),
        contains('not a String'),
      );
    });
  });
}
