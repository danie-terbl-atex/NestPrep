import '../model/device_position.dart';

/// The device this app is running on, as somewhere on the earth.
///
/// It is an interface so a test can drive positions by hand, and so the
/// platform plugin lives in exactly one file (`ENG-09`). It knows nothing about
/// households, members or sharing — that is [LocationReporter]'s job, and the
/// separation is what lets a background implementation replace the reporter
/// without touching this.
abstract interface class LocationSource {
  /// Asks for permission if it has not been asked, and answers whether this
  /// device may report at all. It is the person on this phone who answers, and
  /// nobody in the household can answer for them (live-location ADR-0002).
  Future<LocationConsent> requestConsent();

  /// A fix each time the device has moved [moveBeforeReporting] metres. A
  /// device that is standing still emits nothing, which is the whole point.
  Stream<DevicePosition> watchPosition({required int moveBeforeReporting});
}

/// What the device and its owner said when asked.
enum LocationConsent {
  granted,

  /// Refused this time. Asking again is allowed.
  refused,

  /// Refused in a way only the settings screen can undo.
  refusedForever,

  /// Location is switched off on the device itself, for every app.
  switchedOff,
}
