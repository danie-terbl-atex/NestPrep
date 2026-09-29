import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/booking_repository.dart';
import '../data/shift_directory.dart';
import '../model/shift_booking.dart';

/// The booked-shifts screen (nanny-hub ADR-0006): family books a carer's
/// shifts ahead, cancels them, and — an admin — keeps a carer to them; a
/// carer sees their own. Booking twice on a double tap is refused here
/// (`FE-10`); whether a booking may be made at all is the rules' (`BE-20`).
final class BookingsController extends ChangeNotifier with ActionFailureHolder {
  BookingsController({
    required BookingRepository bookingRepository,
    required ShiftDirectory shiftDirectory,
    required this.householdId,
    required this.viewerMemberId,
    required this.isFamily,
    required this._now,
  }) : _bookings = bookingRepository,
       _directory = shiftDirectory {
    _start();
  }

  final BookingRepository _bookings;
  final ShiftDirectory _directory;
  final DateTime Function() _now;
  final String householdId;
  final String? viewerMemberId;

  /// Family sees and books everybody's shifts; anybody else only their own.
  final bool isFamily;

  StreamSubscription<List<ShiftBooking>>? _subscription;
  AsyncState<List<ShiftBooking>> _upcoming = const AsyncLoading();
  var _isBooking = false;
  final _changingShiftOnly = <String>{};

  /// Bookings not yet over, soonest first.
  AsyncState<List<ShiftBooking>> get upcoming => _upcoming;

  bool get isBooking => _isBooking;

  bool isChangingShiftOnly(String memberId) =>
      _changingShiftOnly.contains(memberId);

  DateTime get now => _now();

  /// Books a shift. True when it was booked; the banner says why when not.
  Future<bool> book({
    required String carerMemberId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? note,
  }) async {
    final by = viewerMemberId;
    if (_isBooking || by == null) return false;
    _isBooking = true;
    notifyListeners();
    var booked = false;
    await runAction(() async {
      await _bookings.book((
        householdId: householdId,
        carerMemberId: carerMemberId,
        startsAt: startsAt,
        endsAt: endsAt,
        note: _tidy(note),
        createdBy: by,
      ));
      booked = true;
    });
    _isBooking = false;
    notifyListeners();
    return booked;
  }

  Future<void> cancel(ShiftBooking booking) =>
      runAction(() => _bookings.cancel(householdId, booking));

  /// Keeps [memberId] to their booked shifts, or lets them see the household
  /// at any time again. The switch waits while the change is on its way.
  Future<void> setShiftOnly(
    String memberId, {
    required bool isShiftOnly,
  }) async {
    if (!_changingShiftOnly.add(memberId)) return;
    notifyListeners();
    await runAction(
      () => _directory.setCarerShiftOnly(
        householdId: householdId,
        memberId: memberId,
        isShiftOnly: isShiftOnly,
      ),
    );
    _changingShiftOnly.remove(memberId);
    notifyListeners();
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    _upcoming = const AsyncLoading();
    notifyListeners();
    _start();
  }

  static String? _tidy(String? note) {
    final text = note?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  void _start() {
    final member = viewerMemberId;
    if (!isFamily && member == null) {
      _upcoming = const AsyncData([]);
      return;
    }
    _subscription = _bookings
        .watchUpcoming(
          householdId,
          from: _now(),
          carerMemberId: isFamily ? null : member,
        )
        .listen(
          (bookings) {
            final now = _now();
            _upcoming = AsyncData(
              [
                for (final booking in bookings)
                  if (!booking.hasClosedBy(now)) booking,
              ]..sort((a, b) => a.startsAt.compareTo(b.startsAt)),
            );
            notifyListeners();
          },
          onError: (Object error) {
            _upcoming = AsyncFailure(
              error is AppFailure ? error : UnknownFailure(error),
            );
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
