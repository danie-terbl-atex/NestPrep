import 'dart:async';

import '../../../shared/failure/app_failure.dart';
import '../model/device_position.dart';
import 'live_location_repository.dart';
import 'location_reporter.dart';
import 'location_source.dart';

/// Reports while the app is in front of somebody, and stops when the window
/// closes (live-location ADR-0001). The only implementation this build ships.
///
/// Two numbers do the work and both are on [LiveLocationRepository], where a
/// reader comparing features can see them: the device offers a fix only after
/// it has moved 100 metres, and no more than one of them every 90 seconds
/// becomes a write. A member who is not moving costs one write for a whole
/// four-hour window.
final class ForegroundLocationReporter implements LocationReporter {
  ForegroundLocationReporter({
    required LocationSource locationSource,
    required LiveLocationRepository liveLocationRepository,
    DateTime Function()? now,
  }) : _source = locationSource,
       _repository = liveLocationRepository,
       _now = now ?? DateTime.now;

  final LocationSource _source;
  final LiveLocationRepository _repository;
  final DateTime Function() _now;
  final StreamController<AppFailure> _problems =
      StreamController<AppFailure>.broadcast();

  StreamSubscription<DevicePosition>? _positions;
  Timer? _windowCloses;
  _Share? _share;
  DateTime? _lastReportedAt;

  @override
  Stream<AppFailure> get problems => _problems.stream;

  @override
  Future<void> start({
    required String householdId,
    required String memberId,
    required DateTime until,
  }) async {
    final share = _Share(
      householdId: householdId,
      memberId: memberId,
      until: until,
    );
    // Resuming a window the person opened before the app was last closed runs
    // through here on every emission of their own document, so saying the same
    // thing twice has to change nothing.
    if (_share == share) return;

    final refusal = switch (await _source.requestConsent()) {
      LocationConsent.granted => null,
      LocationConsent.refused => LocationProblem.permissionRefused,
      LocationConsent.refusedForever =>
        LocationProblem.permissionRefusedForever,
      LocationConsent.switchedOff => LocationProblem.switchedOff,
    };
    if (refusal != null) throw LocationFailure(refusal);

    await _stopReporting();
    _share = share;
    _lastReportedAt = null;
    _positions = _source
        .watchPosition(
          moveBeforeReporting: LiveLocationRepository.moveBeforeReporting,
        )
        .listen(_onPosition, onError: _onSourceFailed);

    final remaining = until.difference(_now());
    _windowCloses = Timer(
      remaining.isNegative ? Duration.zero : remaining,
      () => unawaited(_closeWindow()),
    );
  }

  @override
  Future<void> stop({
    required String householdId,
    required String memberId,
  }) async {
    await _stopReporting();
    await _repository.stopSharing(householdId: householdId, memberId: memberId);
  }

  /// Ends the share and, unlike [stop], has nowhere to throw: the window
  /// closing is not something anybody asked for at that moment, so a failure
  /// goes to [problems] and the screen shows it (`ENG-10`).
  Future<void> _closeWindow() async {
    final share = _share;
    if (share == null) return;
    try {
      await stop(householdId: share.householdId, memberId: share.memberId);
    } on AppFailure catch (failure) {
      _problems.add(failure);
    }
  }

  Future<void> _onPosition(DevicePosition position) async {
    final share = _share;
    if (share == null) return;
    final now = _now();
    final last = _lastReportedAt;
    if (last != null &&
        now.difference(last) < LiveLocationRepository.reportEvery) {
      return;
    }
    // Claimed before the write, not after: two fixes arriving inside the same
    // 90 seconds must not both get through while the first is still in flight.
    _lastReportedAt = now;
    try {
      await _repository.report(
        householdId: share.householdId,
        memberId: share.memberId,
        at: position.at,
        accuracyMetres: position.accuracyMetres,
        sharingUntil: share.until,
      );
    } on AppFailure catch (failure) {
      _problems.add(failure);
    }
  }

  void _onSourceFailed(Object error) {
    // The device stopped producing positions — location switched off while a
    // share was open is the usual way. Silence would look like standing still.
    unawaited(_stopReporting());
    _problems.add(
      error is AppFailure
          ? error
          : const LocationFailure(LocationProblem.reportingStopped),
    );
  }

  Future<void> _stopReporting() async {
    _windowCloses?.cancel();
    _windowCloses = null;
    await _positions?.cancel();
    _positions = null;
    _share = null;
    _lastReportedAt = null;
  }

  /// For a test. The running app holds one of these for its whole life, which
  /// is exactly as long as the provider graph it sits in.
  Future<void> dispose() async {
    await _stopReporting();
    await _problems.close();
  }
}

/// What is being reported, for whom, and until when. Held as one value so
/// "already reporting this" is one comparison and cannot drift.
class _Share {
  const _Share({
    required this.householdId,
    required this.memberId,
    required this.until,
  });

  final String householdId;
  final String memberId;
  final DateTime until;

  @override
  bool operator ==(Object other) =>
      other is _Share &&
      other.householdId == householdId &&
      other.memberId == memberId &&
      other.until == until;

  @override
  int get hashCode => Object.hash(householdId, memberId, until);
}
