import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/house_code_repository.dart';
import '../model/house_codes.dart';
import '../model/shift_booking.dart';
import '../model/shift_window.dart';
import 'shift_pass_controller.dart';

/// The house codes (nanny-hub ADR-0006). Family reads and changes them at any
/// time. Anybody else sees them only inside a shift booked for them: fetched
/// fresh from the server when the window opens, and let go of — off the
/// screen and out of memory — the moment it closes.
///
/// A refusal from the rules is the window being shut, not an error: the
/// server's clock and the pass it checks are the authority (`BE-20`).
final class HouseCodesController extends ChangeNotifier
    with ActionFailureHolder {
  HouseCodesController({
    required HouseCodeRepository houseCodeRepository,
    required this._pass,
    required this.householdId,
    required this.memberId,
    required this.isFamily,
  }) : _codes = houseCodeRepository {
    if (isFamily) {
      unawaited(_fetch());
    } else {
      _pass.addListener(_follow);
      _follow();
    }
  }

  final HouseCodeRepository _codes;
  final ShiftPassController _pass;
  final String householdId;
  final String? memberId;

  /// Family sees and edits every code at any time.
  final bool isFamily;

  AsyncState<HouseCodes> _state = const AsyncLoading();
  bool? _wasOpen;
  var _isDisposed = false;

  AsyncState<HouseCodes> get codes => _state;

  Future<void> retry() async {
    _wasOpen = null;
    if (isFamily) return _fetch();
    _follow();
  }

  Future<void> add(HouseCodeDraft draft) => _change(() async {
    final by = memberId;
    if (by == null) return;
    await _codes.add((householdId: householdId, memberId: by), draft);
  });

  Future<void> update(String codeId, HouseCodeDraft draft) =>
      _change(() => _codes.update(householdId, codeId, draft));

  Future<void> remove(String codeId) =>
      _change(() => _codes.remove(householdId, codeId));

  Future<void> _change(Future<void> Function() write) async {
    await runAction(write);
    if (actionFailure == null) await _fetch();
  }

  void _follow() {
    final window = _pass.window;
    switch (window) {
      case AsyncLoading():
        _set(const AsyncLoading());
      case AsyncFailure(:final failure):
        _set(AsyncFailure(failure));
      case AsyncData(:final value):
        if (value.isOpen == _wasOpen) return;
        _wasOpen = value.isOpen;
        if (value.isOpen) {
          unawaited(_fetch());
        } else {
          _set(AsyncData(CodesClosed(next: _next(value))));
        }
    }
  }

  static ShiftBooking? _next(ShiftWindow window) => switch (window) {
    OffShift(:final next) => next,
    _ => null,
  };

  Future<void> _fetch() async {
    _set(const AsyncLoading());
    try {
      final codes = await _codes.fetch(householdId);
      _set(AsyncData(CodesShown(codes, closesAt: _closesAt())));
    } on PermissionDeniedFailure {
      _set(
        isFamily
            ? const AsyncFailure(PermissionDeniedFailure())
            : AsyncData(CodesClosed(next: _nextBooked())),
      );
    } on AppFailure catch (failure) {
      _set(AsyncFailure(failure));
    }
  }

  DateTime? _closesAt() => switch (_pass.window) {
    AsyncData(value: OnBookedShift(:final booking)) => booking.closesAt,
    _ => null,
  };

  ShiftBooking? _nextBooked() => _pass.stillToCome.firstOrNull;

  void _set(AsyncState<HouseCodes> state) {
    _state = state;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pass.removeListener(_follow);
    super.dispose();
  }
}
