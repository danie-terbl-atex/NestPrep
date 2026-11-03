import '../model/coordinates.dart';
import '../model/family_place.dart';

/// What the phone's OS lets this app do with its location.
enum LocationAccess { always, whileInUse, denied, deniedForever, off }

enum MotionAccess { granted, denied, notNeeded }

class EnginePermissions {
  const EnginePermissions({required this.location, required this.motion});

  final LocationAccess location;
  final MotionAccess motion;

  bool get canShareAlways => location == LocationAccess.always;
}

/// Why the engine stopped on its own.
enum EngineStopReason { refused, permissionRevoked, signedOut, paused }

class EngineStatus {
  const EngineStatus({
    required this.running,
    this.householdId,
    this.memberId,
    this.lastStopReason,
  });

  static const idle = EngineStatus(running: false);

  final bool running;
  final String? householdId;
  final String? memberId;
  final EngineStopReason? lastStopReason;

  bool isSharingFor(String householdId, String memberId) =>
      running && this.householdId == householdId && this.memberId == memberId;
}

class EngineConfig {
  const EngineConfig({
    required this.householdId,
    required this.memberId,
    required this.timeZone,
    required this.foreground,
    required this.places,
    required this.notificationTitle,
    required this.notificationBody,
    required this.notificationChannelName,
    this.notificationPauseLabel,
    this.emulatorHost,
    this.firestorePort = 8080,
    this.authPort = 9099,
  });

  final String householdId;
  final String memberId;
  final String timeZone;
  final bool foreground;
  final List<FamilyPlace> places;
  final String notificationTitle;
  final String notificationBody;
  final String notificationChannelName;
  final String? notificationPauseLabel;
  final String? emulatorHost;
  final int firestorePort;
  final int authPort;
}

/// The phone's own always-on location engine (live-location ADR-0005): native
/// code that keeps reporting with the app closed and writes Firestore itself.
abstract interface class LocationEngine {
  /// Throws a `LocationFailure` when the OS has not allowed it.
  Future<void> start(EngineConfig config);

  /// Flushes what it has recorded, then stops. The live document is the
  /// caller's to delete.
  Future<void> stop();

  Future<EngineStatus> status();

  Future<void> setForeground({required bool foreground});

  Future<void> setPlaces(List<FamilyPlace> places);

  Future<EnginePermissions> permissions();

  Future<EnginePermissions> requestAlways();

  Future<EnginePermissions> requestMotion();

  Future<void> openBatterySettings();

  Future<String?> reverseGeocode(Coordinates at);

  /// Tells the engine the app's Firebase is configured, so it may write.
  Future<void> ready();

  Stream<EngineStopReason> get stopped;
}
