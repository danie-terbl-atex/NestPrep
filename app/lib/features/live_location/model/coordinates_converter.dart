import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import 'coordinates.dart';

/// Stores a position as Firestore's own `GeoPoint`, which is what the rules
/// check with `is latlng` and what a map query would need later.
///
/// A document written by hand in the console, or by an older build, must not
/// take the whole screen down — so anything that is not a `GeoPoint` is a
/// `FormatException` at the boundary rather than a cast (`ENG-09`).
class CoordinatesConverter implements JsonConverter<Coordinates, Object?> {
  const CoordinatesConverter();

  @override
  Coordinates fromJson(Object? json) => switch (json) {
    GeoPoint() => Coordinates(
      latitude: json.latitude,
      longitude: json.longitude,
    ),
    _ => throw FormatException('expected a GeoPoint', json),
  };

  @override
  Object toJson(Coordinates value) => GeoPoint(value.latitude, value.longitude);
}
