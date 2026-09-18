import 'coordinates.dart';

/// One fix from the device this app is running on, before anything is decided
/// about whether to report it. The platform's own position type stops at
/// `GeolocatorLocationSource` and becomes one of these (`ENG-09`).
class DevicePosition {
  const DevicePosition({required this.at, required this.accuracyMetres});

  final Coordinates at;

  /// The radius the device believes it is within, rounded to a metre. It is
  /// stored and shown, because "here now, within 12 m" and "here now, within
  /// 900 m" are different answers to the same question.
  final int accuracyMetres;
}
