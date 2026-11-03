import '../model/coordinates.dart';
import 'location_engine.dart';

/// "12 Oak Street" for a point, from the phone's own geocoder (live-location
/// ADR-0007), remembered per ~100 m so a list that rebuilds asks once.
final class StreetNames {
  StreetNames(this._engine);

  final LocationEngine _engine;
  final Map<(int, int), Future<String?>> _asked = {};

  Future<String?> near(Coordinates at) => _asked.putIfAbsent((
    (at.latitude * 1000).round(),
    (at.longitude * 1000).round(),
  ), () => _engine.reverseGeocode(at));
}
