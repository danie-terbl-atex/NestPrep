import 'dart:math' as math;

/// A point on the earth, in degrees. The Firestore `GeoPoint` stops at the
/// repository edge and becomes one of these, so nothing above `data/` imports
/// the Firestore SDK (`ENG-09`).
class Coordinates {
  const Coordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  /// Metres from here to [other], over the sphere.
  ///
  /// The haversine formula on a mean earth radius. It is wrong by about 0.3%
  /// at worst, which at the distances a household asks about — *how far away
  /// is she* — is metres. Nothing here needs the ellipsoid.
  double metresTo(Coordinates other) {
    const earthRadiusMetres = 6371000.0;
    final dLat = _radians(other.latitude - latitude);
    final dLon = _radians(other.longitude - longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(latitude)) *
            math.cos(_radians(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadiusMetres * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

  @override
  bool operator ==(Object other) =>
      other is Coordinates &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'Coordinates($latitude, $longitude)';
}
