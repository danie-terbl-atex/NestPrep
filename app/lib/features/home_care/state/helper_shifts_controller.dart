import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/helper_shift_repository.dart';
import '../model/home_care_access.dart';
import '../model/shift/helper_shift.dart';

/// Who is clocked in, and the shifts so far (home-care ADR-0007).
///
/// Home-care-wide: the front door's clock card and the shifts screen read the
/// same listener. A helper with `own` asks for exactly her shifts; whoever
/// may `view` reads everybody's. Nothing is read while the switch is off.
final class HelperShiftsController extends ChangeNotifier
    with ActionFailureHolder {
  HelperShiftsController({
    required this._repository,
    required this.householdId,
  });

  final HelperShiftRepository _repository;
  final String householdId;

  HomeCareAccess? _access;
  var _isOn = false;
  StreamSubscription<List<HelperShift>>? _subscription;
  AsyncState<List<HelperShift>> _shifts = const AsyncLoading();
  var _isBusy = false;
  var _isDisposed = false;
  var _listening = 0;

  /// Whether the switch is on and home care is open to the viewer.
  bool get isAvailable => _isOn && (_access?.isVisible ?? false);

  /// Whether the viewer clocks in and out herself.
  bool get clocksIn => isAvailable && (_access?.clocksIn ?? false);

  /// The newest shifts first.
  AsyncState<List<HelperShift>> get shifts => _shifts;

  /// A start or an end is on its way.
  bool get isBusy => _isBusy;

  /// The viewer's own open shift, if she is clocked in.
  HelperShift? get ownOpenShift => openShiftOf(_access?.viewerMemberId);

  HelperShift? openShiftOf(String? helperId) => switch (_shifts) {
    AsyncData(:final value) when helperId != null =>
      value
          .where((shift) => shift.isOpen && shift.helperId == helperId)
          .firstOrNull,
    _ => null,
  };

  bool canEnd(HelperShift shift) =>
      shift.isOpen && (_access?.canEndShiftOf(shift.helperId) ?? false);

  /// Clocks the viewer in. Does nothing while she is already on shift, or
  /// before the shifts have been read — the list is what says she is not.
  Future<void> start() async {
    final memberId = _access?.viewerMemberId;
    if (memberId == null || _shifts is! AsyncData || ownOpenShift != null) {
      return;
    }
    await _run(
      () => _repository.startShift(
        householdId: householdId,
        helperId: memberId,
        by: memberId,
      ),
    );
  }

  /// Clocks [shift] out — and any other shift of that helper a phone that was
  /// offline left open, so an end is never undone by a second one.
  Future<void> end(HelperShift shift) async {
    final memberId = _access?.viewerMemberId;
    if (memberId == null || !canEnd(shift)) return;
    final open = switch (_shifts) {
      AsyncData(:final value) => [
        for (final other in value)
          if (other.isOpen && other.helperId == shift.helperId) other.id,
      ],
      _ => const <String>[],
    };
    await _run(() async {
      for (final shiftId in {shift.id, ...open}) {
        await _repository.endShift(
          householdId: householdId,
          shiftId: shiftId,
          by: memberId,
        );
      }
    });
  }

  /// Whose shifts to ask for: her own for anybody who clocks in and does not
  /// manage, so her open shift is never pushed out of the list by others'.
  String? _scopeOf(HomeCareAccess access) =>
      access.clocksIn && !access.canManage
      ? access.viewerMemberId
      : access.jobScope;

  Future<void> _run(Future<void> Function() action) async {
    if (_isBusy) return;
    _isBusy = true;
    notifyListeners();
    try {
      await runAction(action);
    } finally {
      _isBusy = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  /// The shell's grant or the switch changed. Called while the shell builds,
  /// so it says nothing itself unless what it reads moved.
  void follow(HomeCareAccess access, {required bool isOn}) {
    final before = _access;
    final scopeMoved =
        before == null ||
        _scopeOf(access) != _scopeOf(before) ||
        access.isVisible != before.isVisible ||
        isOn != _isOn;
    final moved = scopeMoved || access != before;
    _access = access;
    _isOn = isOn;
    if (scopeMoved) unawaited(_listen());
    if (!moved) return;
    scheduleMicrotask(() {
      if (!_isDisposed) notifyListeners();
    });
  }

  Future<void> retry() async {
    await _listen();
    if (!_isDisposed) notifyListeners();
  }

  Future<void> _listen() async {
    final mine = ++_listening;
    final old = _subscription;
    _subscription = null;
    _shifts = const AsyncLoading();
    await old?.cancel();
    final access = _access;
    if (_isDisposed || mine != _listening) return;
    if (!_isOn || access == null || !access.isVisible) return;
    _subscription = _repository
        .watchShifts(householdId, helperId: _scopeOf(access))
        .listen(
          (shifts) {
            if (_isDisposed) return;
            _shifts = AsyncData(shifts);
            notifyListeners();
          },
          onError: (Object error) {
            if (_isDisposed) return;
            _shifts = AsyncFailure(
              error is AppFailure ? error : UnknownFailure(error),
            );
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
