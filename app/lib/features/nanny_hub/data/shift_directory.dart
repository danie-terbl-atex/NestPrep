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
}
