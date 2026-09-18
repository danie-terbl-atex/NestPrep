import '../features/live_location/data/foreground_location_reporter.dart';
import '../features/live_location/data/live_location_repository.dart';
import '../features/live_location/data/location_reporter.dart';
import '../features/live_location/data/location_source.dart';

/// When this build reports a member's position, chosen at compile time with
/// `--dart-define=NESTPREP_LOCATION_REPORTING=foreground|background`.
/// Foreground is the default, and today it is the only one that exists
/// (live-location ADR-0001).
enum LocationReporting {
  /// While the app is open, for the window the member chose. What ships.
  foreground,

  /// Reporting that carries on when the app is not in front of anybody.
  ///
  /// The constant is here, and [locationReporterFor] refuses it, because the
  /// seam is the point: a background implementation replaces
  /// [LocationReporter] and nothing else. What it needs first is not code — it
  /// is `ACCESS_BACKGROUND_LOCATION` in the manifest, and that needs a Play
  /// Console prominent-disclosure declaration and a demo video. See
  /// live-location phase 2.
  background;

  static const defineName = 'NESTPREP_LOCATION_REPORTING';
  static const _defined = String.fromEnvironment(
    defineName,
    defaultValue: 'foreground',
  );

  static LocationReporting fromEnvironment() => fromName(_defined);

  /// Parses the define's value.
  ///
  /// Separate from [fromEnvironment] for the same reason `BackendTarget` splits
  /// them: `_defined` is a compile-time constant, so under `flutter test` it is
  /// always `'foreground'` and every other branch is unreachable through
  /// [fromEnvironment].
  static LocationReporting fromName(String name) => switch (name) {
    'foreground' => LocationReporting.foreground,
    'background' => LocationReporting.background,
    _ => throw ArgumentError.value(
      name,
      defineName,
      'expected "foreground" or "background"',
    ),
  };
}

/// The reporter this build uses, or a refusal to start.
///
/// A build asking for `background` **fails here** rather than quietly falling
/// back. A silent downgrade would mean an app somebody believed was reporting
/// in the background was not, and the person relying on it would find that out
/// by not being found (live-location ADR-0002).
LocationReporter locationReporterFor(
  LocationReporting reporting, {
  required LocationSource locationSource,
  required LiveLocationRepository liveLocationRepository,
}) => switch (reporting) {
  LocationReporting.foreground => ForegroundLocationReporter(
    locationSource: locationSource,
    liveLocationRepository: liveLocationRepository,
  ),
  LocationReporting.background => throw UnsupportedError(
    'no background location reporter exists in this build — '
    'live-location phase 2 carries the Play Console prominent-disclosure '
    'declaration the manifest permissions need',
  ),
};
