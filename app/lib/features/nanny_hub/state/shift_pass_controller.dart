import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/best_effort.dart';
import '../data/booking_repository.dart';
import '../model/shift_booking.dart';
import '../model/shift_window.dart';

/// Where the viewer stands against the shifts a parent booked for them, kept
/// true as the clock moves (nanny-hub ADR-0006). It lives on the household
/// shell, because a carer kept to their shifts sees nothing of the household
/// outside one, and the house codes open only inside one for anybody who is
/// not family.
///
/// It also keeps the viewer's **pass** — the one document naming which
/// booking they are on, or next on — so the rules have a booking to check the
/// time against. The pass is written ahead, for the next shift, so the window
/// opens on time even without a signal at the gate.
final class ShiftPassController extends ChangeNotifier {
  ShiftPassController({
    required BookingRepository bookingRepository,
    required this.householdId,
    required this.memberId,
    required this.isFamily,
    required this._now,
  }) : _bookings = bookingRepository {
    _start();
  }

  final BookingRepository _bookings;
  final DateTime Function() _now;
  final String householdId;

  /// The viewer's profile; null for an account that claimed none, which is
  /// never on a booked shift.
  final String? memberId;
  final bool isFamily;

  StreamSubscription<List<ShiftBooking>>? _subscription;
  List<ShiftBooking> _list = const [];
  Timer? _boundary;
  String? _passNames;
  AsyncState<ShiftWindow> _window = const AsyncLoading();
  var _isDisposed = false;

  AsyncState<ShiftWindow> get window => _window;

  /// True only when the window is known to be open.
  bool get isOpen => switch (_window) {
    AsyncData(:final value) => value.isOpen,
    _ => false,
  };

  /// The viewer's own bookings still to come or under way, soonest first.
  List<ShiftBooking> get stillToCome {
    final now = _now();
    return [
      for (final booking in _list)
        if (!booking.hasClosedBy(now)) booking,
    ]..sort((a, b) => a.opensAt.compareTo(b.opensAt));
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    _subscription = null;
    _window = const AsyncLoading();
    notifyListeners();
    _start();
  }

  void _start() {
    final member = memberId;
    if (isFamily) {
      _window = const AsyncData(AlwaysOpen());
      return;
    }
    if (member == null) {
      _window = const AsyncData(OffShift());
      return;
    }
    _subscription = _bookings
        .watchUpcoming(householdId, from: _now(), carerMemberId: member)
        .listen(
          (bookings) {
            _list = bookings;
            _recompute();
          },
          onError: (Object error) {
            _window = AsyncFailure(
              error is AppFailure ? error : UnknownFailure(error),
            );
            _notify();
          },
        );
  }

  /// Works out the window now, names the booking on the pass if it changed,
  /// and wakes again at the next edge — the current window's close, or the
  /// next one's open.
  void _recompute() {
    final member = memberId;
    if (member == null || _isDisposed) return;
    final now = _now();
    final window = shiftWindowAt(now, memberId: member, bookings: _list);
    _window = AsyncData(window);
    final named = switch (window) {
      OnBookedShift(:final booking) => booking,
      OffShift(:final next) => next,
      AlwaysOpen() => null,
    };
    if (named != null && named.id != _passNames) unawaited(_savePass(named));
    _scheduleEdge(now, window);
    _notify();
  }

  /// A pass that could not be written is written again at the next edge; the
  /// rules refuse the codes meanwhile, which the screen says (`ENG-10`).
  Future<void> _savePass(ShiftBooking booking) async {
    _passNames = booking.id;
    final failed = await bestEffort(
      'name the booked shift on the pass',
      code: 'firestore',
      run: () => _bookings.savePass(householdId, booking),
    );
    if (failed != null && _passNames == booking.id) _passNames = null;
  }

  void _scheduleEdge(DateTime now, ShiftWindow window) {
    _boundary?.cancel();
    final edge = switch (window) {
      OnBookedShift(:final booking) => booking.closesAt,
      OffShift(:final next) => next?.opensAt,
      AlwaysOpen() => null,
    };
    if (edge == null) return;
    // A second past the edge, so the window is plainly on its far side.
    final wait = edge.difference(now) + const Duration(seconds: 1);
    _boundary = Timer(wait.isNegative ? Duration.zero : wait, _recompute);
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _boundary?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
