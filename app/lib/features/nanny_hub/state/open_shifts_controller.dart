import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/log/app_log.dart';
import '../../../shared/state/action_failure.dart';
import '../data/shift_directory.dart';
import '../data/shift_repository.dart';
import '../model/nanny_access.dart';
import '../model/shift.dart';

/// The shifts still open that the viewer may end — all a locked nanny hub
/// keeps (subscriptions ADR-0009): `endNannyShift` is not Premium, so a
/// household whose Premium ended can still close the shift it left open.
///
/// One listener, on the open shifts alone, and only for somebody who could
/// end one. A read that fails leaves nothing to end, so the locked place is
/// simply the locked place.
final class OpenShiftsController extends ChangeNotifier
    with ActionFailureHolder {
  OpenShiftsController({
    required ShiftRepository shiftRepository,
    required ShiftDirectory shiftDirectory,
    required this.householdId,
    required this.access,
  }) : _repository = shiftRepository,
       _directory = shiftDirectory {
    _listen();
  }

  final ShiftRepository _repository;
  final ShiftDirectory _directory;
  final String householdId;
  final NannyAccess access;

  StreamSubscription<List<Shift>>? _subscription;
  List<Shift> _open = const [];
  var _isEnding = false;
  var _isDisposed = false;

  /// Whether [access] could end any shift at all, and so whether this is
  /// worth creating.
  static bool listensFor(NannyAccess access) =>
      access.canView &&
      access.canEdit &&
      (access.isFamily || access.viewerMemberId != null);

  List<Shift> get shifts => [
    for (final shift in _open)
      if (shift.isOpen && access.mayEndShiftOf(shift.carerMemberId)) shift,
  ];

  bool get isEnding => _isEnding;

  bool isOwn(Shift shift) => shift.carerMemberId == access.viewerMemberId;

  /// Ends [shift] with no closing note, which is all the callable needs; the
  /// summary is still written from what was logged.
  Future<void> end(Shift shift) async {
    if (_isEnding || !access.mayEndShiftOf(shift.carerMemberId)) return;
    _isEnding = true;
    notifyListeners();
    try {
      await runAction(
        () => _directory.endShift(householdId: householdId, shiftId: shift.id),
      );
    } finally {
      _isEnding = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void _listen() {
    if (!listensFor(access)) return;
    _subscription = _repository
        .watchOpenShifts(householdId)
        .listen(
          (shifts) {
            if (_isDisposed) return;
            _open = shifts;
            notifyListeners();
          },
          onError: (Object error) {
            AppLog.failure(
              'read the open shifts of a locked nanny hub',
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
