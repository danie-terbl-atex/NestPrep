import 'dart:async';

import 'package:nestprep/features/live_location/data/live_location_repository.dart';
import 'package:nestprep/features/live_location/data/location_reporter.dart';
import 'package:nestprep/features/live_location/data/location_source.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/live_location/model/device_position.dart';
import 'package:nestprep/features/live_location/model/member_location.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

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
}
