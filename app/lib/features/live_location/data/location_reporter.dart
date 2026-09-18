import '../../../shared/failure/app_failure.dart';

/// What reports a member's own position, for as long as they said to.
///
/// **This is the seam.** A background implementation — a foreground service on
/// Android, significant-change updates on iOS — replaces exactly this and
/// nothing else: not the model, not the rules, not the screen. Which one a
/// build has is decided once, at compile time, in
/// `app/lib/app/location_reporting.dart` (live-location ADR-0001).
///
/// It lives above the route, not on it, because reporting continues when the
/// person navigates away from the screen. It stops when the window closes, when
/// they stop it, or when the app does.
abstract interface class LocationReporter {
  /// Starts reporting [memberId]'s position until [until], asking the person on
  /// this device for permission first.
  ///
  /// Throws a [LocationFailure] when this device may not report — a refusal is
  /// something the screen says in words, not something it discovers by nothing
  /// happening (`FE-09`).
  ///
  /// Calling it again for a window already being reported changes nothing, so
  /// resuming a share the person opened before the app was last closed is safe
  /// to do on every emission.
  Future<void> start({
    required String householdId,
    required String memberId,
    required DateTime until,
  });

  /// Stops now, and removes what the household can see.
  Future<void> stop({required String householdId, required String memberId});

  /// Anything that went wrong after [start] returned — location switched off
  /// mid-share, the write refused. A share that stopped silently is the one
  /// failure this feature must not have (`FE-08`).
  Stream<AppFailure> get problems;
}
