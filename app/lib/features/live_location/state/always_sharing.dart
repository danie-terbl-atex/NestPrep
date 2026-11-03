import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/emulator_endpoint.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../../shared/log/best_effort.dart';
import '../data/foreground_location_reporter.dart';
import '../data/live_location_repository.dart';
import '../data/location_engine.dart';
import '../data/location_reporter.dart';
import '../model/family_place.dart';

/// What the signed-in person's phone needs to know to share always.
class AlwaysSharingSubject {
  const AlwaysSharingSubject({
    required this.householdId,
    required this.memberId,
    required this.timeZone,
    required this.notificationTitle,
    required this.notificationBody,
    required this.notificationChannelName,
    required this.notificationPauseLabel,
  });

  final String householdId;
  final String memberId;
  final String timeZone;
  final String notificationTitle;
  final String notificationBody;
  final String notificationChannelName;
  final String notificationPauseLabel;
}

/// This phone's always-on sharing (live-location ADR-0008, ADR-0005). App-wide,
/// because the engine outlives every screen, every household switch and the
/// kid home, which has no household shell.
final class AlwaysSharing extends ChangeNotifier with WidgetsBindingObserver {
  AlwaysSharing({
    required this._engine,
    required LiveLocationRepository liveLocationRepository,
    required LocationReporter locationReporter,
    this._emulator,
    bool observeLifecycle = true,
  }) : _repository = liveLocationRepository,
       _reporter = locationReporter,
       _observesLifecycle = observeLifecycle {
    _stopped = _engine.stopped.listen(
      _onStopped,
      onError: (Object error) => AppLog.failure(
        'location engine events',
        code: 'engine-events-failed',
        error: error,
      ),
    );
    if (observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _foreground =
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    }
    unawaited(refresh());
  }

  final LocationEngine _engine;
  final LiveLocationRepository _repository;
  final LocationReporter _reporter;
  final EmulatorEndpoint? _emulator;
  final bool _observesLifecycle;
  StreamSubscription<EngineStopReason>? _stopped;

  EngineStatus _status = EngineStatus.idle;
  EnginePermissions? _permissions;
  EngineStopReason? _stoppedBecause;
  bool _foreground = true;
  bool _busy = false;
  bool _stoppingForLapse = false;

  EngineStatus get status => _status;
  EnginePermissions? get permissions => _permissions;
  EngineStopReason? get stoppedBecause => _stoppedBecause;
  bool get busy => _busy;

  bool isSharingFor(String householdId, String memberId) =>
      _status.isSharingFor(householdId, memberId);

  Future<void> refresh() async {
    await bestEffort(
      'location engine status',
      code: 'engine-status-failed',
      run: () async {
        _status = await _engine.status();
        _permissions = await _engine.permissions();
        _stoppedBecause ??= _status.running ? null : _status.lastStopReason;
      },
    );
    notifyListeners();
  }

  /// Asks the OS for "all the time" (and motion) when it is not already
  /// given, then starts. Throws a [LocationFailure] the screen puts in words.
  Future<void> start(
    AlwaysSharingSubject subject, {
    required List<FamilyPlace> places,
  }) => _while(() async {
    var permissions = await _engine.permissions();
    if (permissions.location == LocationAccess.off) {
      throw const LocationFailure(LocationProblem.switchedOff);
    }
    // Android 11+ grants background only as a second request, after
    // while-in-use; iOS upgrades to Always the same way.
    for (var asked = 0; asked < 2 && !permissions.canShareAlways; asked++) {
      permissions = await _engine.requestAlways();
      if (permissions.location == LocationAccess.deniedForever) break;
    }
    if (!permissions.canShareAlways) {
      _permissions = permissions;
      throw const LocationFailure(LocationProblem.alwaysRefused);
    }
    if (permissions.motion == MotionAccess.denied) {
      permissions = await _engine.requestMotion();
    }
    _permissions = permissions;
    await _reporter.stopCurrent(removePin: false);
    final emulator = _emulator;
    await _engine.start(
      EngineConfig(
        householdId: subject.householdId,
        memberId: subject.memberId,
        timeZone: subject.timeZone,
        foreground: _foreground,
        places: places,
        notificationTitle: subject.notificationTitle,
        notificationBody: subject.notificationBody,
        notificationChannelName: subject.notificationChannelName,
        notificationPauseLabel: subject.notificationPauseLabel,
        emulatorHost: emulator?.host,
        firestorePort: emulator?.firestorePort ?? 8080,
        authPort: emulator?.authPort ?? 9099,
      ),
    );
    _stoppedBecause = null;
    _status = await _engine.status();
  });

  /// Pausing is stopping: the household sees nothing until it starts again.
  /// The native engine is always told, whatever this side last heard, so no
  /// config outlives the person's choice.
  Future<void> stop({required String householdId, required String memberId}) =>
      _while(() async {
        await _engine.stop();
        _status = EngineStatus.idle;
        await removePin(
          () => _repository.stopSharing(
            householdId: householdId,
            memberId: memberId,
          ),
        );
        _status = await _engine.status();
      });

  /// Before an account signs out of this phone: nothing may go on reporting
  /// as somebody who is no longer here.
  Future<void> stopBeforeSignOut() async {
    final status = _status;
    await bestEffort(
      'location stop before sign-out',
      code: 'engine-sign-out-stop-failed',
      run: () async {
        await _reporter.stopCurrent(removePin: true);
        await _engine.stop();
        final householdId = status.householdId;
        final memberId = status.memberId;
        if (status.running && householdId != null && memberId != null) {
          await removePin(
            () => _repository.stopSharing(
              householdId: householdId,
              memberId: memberId,
            ),
          );
        }
      },
    );
    _status = EngineStatus.idle;
    notifyListeners();
  }

  /// Premium ended: stop, once, and say why.
  Future<void> stopForLapse({
    required String householdId,
    required String memberId,
  }) async {
    if (_stoppingForLapse || !isSharingFor(householdId, memberId)) return;
    _stoppingForLapse = true;
    try {
      final failure = await bestEffort(
        'always sharing lapse',
        code: 'engine-lapse-stop-failed',
        run: () => stop(householdId: householdId, memberId: memberId),
      );
      if (failure == null) _stoppedBecause = EngineStopReason.refused;
      notifyListeners();
    } finally {
      _stoppingForLapse = false;
    }
  }

  Future<void> placesChanged(List<FamilyPlace> places) async {
    if (!_status.running) return;
    await bestEffort(
      'location engine places',
      code: 'engine-places-failed',
      run: () => _engine.setPlaces(places),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => unawaited(
    appInForeground(foreground: state == AppLifecycleState.resumed),
  );

  Future<void> appInForeground({required bool foreground}) async {
    _foreground = foreground;
    if (foreground) await refresh();
    if (!_status.running) return;
    await bestEffort(
      'location engine cadence',
      code: 'engine-cadence-failed',
      run: () => _engine.setForeground(foreground: foreground),
    );
  }

  Future<void> openBatterySettings() => _engine.openBatterySettings();

  void dismissStopReason() {
    _stoppedBecause = null;
    notifyListeners();
  }

  void _onStopped(EngineStopReason reason) {
    _stoppedBecause = reason == EngineStopReason.paused ? null : reason;
    _status = EngineStatus.idle;
    notifyListeners();
  }

  Future<void> _while(Future<void> Function() work) async {
    _busy = true;
    notifyListeners();
    try {
      await work();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_observesLifecycle) WidgetsBinding.instance.removeObserver(this);
    unawaited(_stopped?.cancel());
    super.dispose();
  }
}
