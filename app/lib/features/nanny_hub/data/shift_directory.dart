/// What a shift needs that Security Rules cannot do, and that is therefore a
/// Cloud Function (foundation ADR-0002, nanny-hub ADR-0002).
abstract interface class ShiftDirectory {
  /// Ends a shift and writes the parents' summary from its log, in one
  /// transaction. Refuses with a `NannyHubProblem` when the shift has already
  /// ended, is somebody else's, or the hub is not the caller's to write.
  Future<void> endShift({
    required String householdId,
    required String shiftId,
    String? closingNote,
  });

  /// Keeps a carer to the shifts a parent books for them — or lets them see
  /// the household at any time again (nanny-hub ADR-0006). Admin only; a
  /// member who is not a carer is refused with `NannyHubProblem.notACarer`.
  Future<void> setCarerShiftOnly({
    required String householdId,
    required String memberId,
    required bool isShiftOnly,
  });
}
