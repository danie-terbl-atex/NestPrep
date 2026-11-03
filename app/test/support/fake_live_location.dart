import 'dart:async';

import 'package:nestprep/features/live_location/data/live_location_repository.dart';
import 'package:nestprep/features/live_location/data/location_engine.dart';
import 'package:nestprep/features/live_location/data/location_reporter.dart';
import 'package:nestprep/features/live_location/data/location_source.dart';
import 'package:nestprep/features/live_location/data/places_repository.dart';
import 'package:nestprep/features/live_location/data/trail_repository.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/live_location/model/device_position.dart';
import 'package:nestprep/features/live_location/model/family_place.dart';
import 'package:nestprep/features/live_location/model/member_location.dart';
import 'package:nestprep/features/live_location/model/trail.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// Stands in for Firestore behind the controller, so a test drives the live
/// stream by hand and nothing pumps the SDK (foundation ADR-0006).
final class FakeLiveLocationRepository implements LiveLocationRepository {
  final _locations = StreamController<List<MemberLocation>>.broadcast();

  /// Set to make the next write fail, the way a rules denial does.
  AppFailure? failWritesWith;

  final reported =
      <
        ({
          String householdId,
          String memberId,
          Coordinates at,
          int accuracyMetres,
          DateTime sharingUntil,
        })
      >[];
  final stopped = <({String householdId, String memberId})>[];

  void emitLocations(List<MemberLocation> locations) =>
      _locations.add(locations);

  void failLocationsWith(Object error) => _locations.addError(error);

  Future<void> close() => _locations.close();

  @override
  Stream<List<MemberLocation>> watchLocations(String householdId) =>
      _locations.stream;

  @override
  Future<void> report({
    required String householdId,
    required String memberId,
    required Coordinates at,
    required int accuracyMetres,
    required DateTime sharingUntil,
  }) async {
    _refuseIfAsked();
    reported.add((
      householdId: householdId,
      memberId: memberId,
      at: at,
      accuracyMetres: accuracyMetres,
      sharingUntil: sharingUntil,
    ));
  }

  @override
  Future<void> stopSharing({
    required String householdId,
    required String memberId,
  }) async {
    _refuseIfAsked();
    stopped.add((householdId: householdId, memberId: memberId));
  }

  void _refuseIfAsked() {
    final failure = failWritesWith;
    if (failure != null) throw failure;
  }
}

/// The device, with its answers decided by the test rather than by a person
/// holding a phone.
final class FakeLocationSource implements LocationSource {
  final _positions = StreamController<DevicePosition>.broadcast();

  LocationConsent consent = LocationConsent.granted;
  int consentsAsked = 0;
  int? watchedWith;

  void emitPosition(DevicePosition position) => _positions.add(position);
  void failPositionsWith(Object error) => _positions.addError(error);
  Future<void> close() => _positions.close();

  @override
  Future<LocationConsent> requestConsent() async {
    consentsAsked += 1;
    return consent;
  }

  /// What [positionIfAlreadyAllowed] answers: null is *not allowed yet*.
  Coordinates? alreadyAllowedAt;

  @override
  Future<Coordinates?> positionIfAlreadyAllowed({
    Duration within = const Duration(seconds: 5),
  }) async => alreadyAllowedAt;

  @override
  Stream<DevicePosition> watchPosition({required int moveBeforeReporting}) {
    watchedWith = moveBeforeReporting;
    return _positions.stream;
  }
}

/// The reporter behind the controller. It records what it was asked for and
/// says nothing to any device.
final class FakeLocationReporter implements LocationReporter {
  final _problems = StreamController<AppFailure>.broadcast();

  AppFailure? refuseStartWith;
  AppFailure? refuseStopWith;

  final started = <({String householdId, String memberId, DateTime until})>[];
  final stopped = <({String householdId, String memberId})>[];

  void reportProblem(AppFailure failure) => _problems.add(failure);
  Future<void> close() => _problems.close();

  @override
  Stream<AppFailure> get problems => _problems.stream;

  @override
  Future<void> start({
    required String householdId,
    required String memberId,
    required DateTime until,
  }) async {
    final refusal = refuseStartWith;
    if (refusal != null) throw refusal;
    started.add((householdId: householdId, memberId: memberId, until: until));
  }

  @override
  Future<void> stop({
    required String householdId,
    required String memberId,
  }) async {
    final refusal = refuseStopWith;
    if (refusal != null) throw refusal;
    stopped.add((householdId: householdId, memberId: memberId));
  }

  final currentStops = <bool>[];

  @override
  Future<void> stopCurrent({required bool removePin}) async =>
      currentStops.add(removePin);
}

final class FakePlacesRepository implements PlacesRepository {
  final _places = StreamController<List<FamilyPlace>>.broadcast();
  final saved = <FamilyPlace>[];
  final deleted = <String>[];
  AppFailure? failWritesWith;

  void emitPlaces(List<FamilyPlace> places) => _places.add(places);

  void emitPlacesError(Object error) => _places.addError(error);

  Future<void> close() => _places.close();

  @override
  Stream<List<FamilyPlace>> watchPlaces(String householdId) => _places.stream;

  @override
  Future<void> save(String householdId, FamilyPlace place) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    saved.add(place);
  }

  @override
  Future<void> delete(String householdId, String placeId) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    deleted.add(placeId);
  }
}

final class FakeTrailRepository implements TrailRepository {
  final days = <String, TrailDay>{};
  final asked = <CalendarDate>[];
  AppFailure? failWith;
  int cleared = 0;

  @override
  Future<TrailDay> loadDay({
    required String householdId,
    required String memberId,
    required CalendarDate day,
    required DateTime from,
    required DateTime to,
  }) async {
    asked.add(day);
    final failure = failWith;
    if (failure != null) throw failure;
    return days[day.iso] ?? TrailDay.empty;
  }

  @override
  Future<void> clearHistory({
    required String householdId,
    required String memberId,
  }) async => cleared++;
}

final class FakeLocationEngine implements LocationEngine {
  final _stopped = StreamController<EngineStopReason>.broadcast();
  EnginePermissions current = const EnginePermissions(
    location: LocationAccess.always,
    motion: MotionAccess.granted,
  );
  EnginePermissions afterAskingAlways = const EnginePermissions(
    location: LocationAccess.always,
    motion: MotionAccess.granted,
  );
  List<EnginePermissions>? afterAskingAlwaysSequence;
  EngineStatus running = EngineStatus.idle;
  final started = <EngineConfig>[];
  int stops = 0;
  int alwaysAsked = 0;
  final placeUpdates = <List<FamilyPlace>>[];
  final cadence = <bool>[];

  void stopOnItsOwn(EngineStopReason reason) {
    running = EngineStatus(running: false, lastStopReason: reason);
    _stopped.add(reason);
  }

  Future<void> close() => _stopped.close();

  @override
  Future<void> start(EngineConfig config) async {
    started.add(config);
    running = EngineStatus(
      running: true,
      householdId: config.householdId,
      memberId: config.memberId,
    );
  }

  @override
  Future<void> stop() async {
    stops++;
    running = EngineStatus.idle;
  }

  @override
  Future<EngineStatus> status() async => running;

  @override
  Future<void> setForeground({required bool foreground}) async =>
      cadence.add(foreground);

  @override
  Future<void> setPlaces(List<FamilyPlace> places) async =>
      placeUpdates.add(places);

  @override
  Future<EnginePermissions> permissions() async => current;

  @override
  Future<EnginePermissions> requestAlways() async {
    alwaysAsked++;
    final sequence = afterAskingAlwaysSequence;
    current = sequence != null && sequence.isNotEmpty
        ? sequence.removeAt(0)
        : afterAskingAlways;
    return current;
  }

  @override
  Future<EnginePermissions> requestMotion() async => current;

  @override
  Future<void> openBatterySettings() async {}

  @override
  Future<String?> reverseGeocode(Coordinates at) async => null;

  @override
  Future<void> ready() async {}

  @override
  Stream<EngineStopReason> get stopped => _stopped.stream;
}

/// The engine reporting for Sam in the fixtures' household.
final class EngineStatusForTest extends EngineStatus {
  const EngineStatusForTest()
    : super(running: true, householdId: 'h1', memberId: 'm-sam');
}
