import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/log/app_log.dart';
import '../../../shared/state/action_failure.dart';
import '../data/helper_shift_repository.dart';
import '../model/home_care_access.dart';
import '../model/shift/helper_shift.dart';

/// The shifts still open that the viewer may clock out — all a locked home
/// care keeps (subscriptions ADR-0009): a household whose Premium ended must
/// still be able to close the shift it left open, which the rules allow.
///
/// One listener, on the open shifts alone: everybody's for whoever manages
/// home care, the viewer's own for anybody else. A read that fails leaves
/// nothing to end, so the locked place is simply the locked place.
final class OpenHelperShiftsController extends ChangeNotifier
    with ActionFailureHolder {
  OpenHelperShiftsController({
    required this._repository,
    required this.householdId,
    required this.access,
  }) {
    _listen();
  }

  final HelperShiftRepository _repository;
  final String householdId;
  final HomeCareAccess access;

  StreamSubscription<List<HelperShift>>? _subscription;
  List<HelperShift> _open = const [];
  var _isBusy = false;
  var _isDisposed = false;

  /// One open shift per helper, of those the viewer may end.
  List<HelperShift> get shifts {
    final seen = <String>{};
    return [
      for (final shift in _open)
        if (shift.isOpen &&
            access.canEndShiftOf(shift.helperId) &&
            seen.add(shift.helperId))
          shift,
    ];
  }

  bool get isBusy => _isBusy;

  bool isOwn(HelperShift shift) => shift.helperId == access.viewerMemberId;

  /// Clocks [shift] out, with any other shift of that helper a phone that was
  /// offline left open.
  Future<void> end(HelperShift shift) async {
    final memberId = access.viewerMemberId;
    if (_isBusy || memberId == null || !access.canEndShiftOf(shift.helperId)) {
      return;
    }
    final ids = {
      shift.id,
      for (final other in _open)
        if (other.isOpen && other.helperId == shift.helperId) other.id,
    };
    _isBusy = true;
    notifyListeners();
    try {
      await runAction(() async {
        for (final shiftId in ids) {
          await _repository.endShift(
            householdId: householdId,
            shiftId: shiftId,
            by: memberId,
          );
        }
      });
    } finally {
      _isBusy = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void _listen() {
    final memberId = access.viewerMemberId;
    if (!access.isVisible || (!access.canManage && memberId == null)) return;
    _subscription = _repository
        .watchOpenShifts(
          householdId,
          helperId: access.canManage ? null : memberId,
        )
        .listen(
          (shifts) {
            if (_isDisposed) return;
            _open = shifts;
            notifyListeners();
          },
          onError: (Object error) {
            AppLog.failure(
              'read the open shifts of a locked home care',
              code: 'firestore',
              error: error,
            );
            if (_isDisposed) return;
            _open = const [];
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
