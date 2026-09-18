import 'package:geolocator/geolocator.dart';

import '../model/coordinates.dart';
import '../model/device_position.dart';
import 'location_source.dart';

/// The one file that knows the platform plugin exists. Its `Position` and its
/// `LocationPermission` stop here (`ENG-09`).
///
/// Accuracy is `medium` — the fused and network providers rather than a
/// continuously held GNSS receiver. It answers "are they still at school", not
/// "which room", and nobody asked for the second one (live-location ADR-0001).
final class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  @override
  Future<LocationConsent> requestConsent() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationConsent.switchedOff;
    }
    final existing = await Geolocator.checkPermission();
    final granted = existing == LocationPermission.denied
        ? await Geolocator.requestPermission()
        : existing;
    return switch (granted) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationConsent.granted,
      LocationPermission.deniedForever => LocationConsent.refusedForever,
      // `unableToDetermine` is a browser answer and this app has no web build;
      // treating it as a refusal is the safe direction, because the other one
      // is reporting somebody's position without knowing they agreed.
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => LocationConsent.refused,
    };
  }

  @override
  Stream<DevicePosition> watchPosition({required int moveBeforeReporting}) =>
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: moveBeforeReporting,
        ),
      ).map(
        (position) => DevicePosition(
          at: Coordinates(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
          accuracyMetres: position.accuracy.round(),
        ),
      );
}
