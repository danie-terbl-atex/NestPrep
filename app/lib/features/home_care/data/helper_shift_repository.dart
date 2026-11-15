import '../model/shift/helper_shift.dart';

/// A helper's clocked shifts (home-care ADR-0007).
abstract interface class HelperShiftRepository {
  /// About three months of one helper clocking in daily (`BE-08`).
  static const shiftLimit = 100;

  /// The newest shifts first. [helperId] is null to read everybody's — for
  /// whoever may `view` home care — and otherwise the one helper an `own`
  /// grant must ask for.
  Stream<List<HelperShift>> watchShifts(String householdId, {String? helperId});

  /// More shifts left open than a household has helpers.
  static const openShiftLimit = 20;

  /// Only the shifts nobody has clocked out, scoped as [watchShifts] is: all
  /// a locked home care still reads, so a shift left open when Premium ended
  /// can be closed (subscriptions ADR-0009).
  Stream<List<HelperShift>> watchOpenShifts(
    String householdId, {
    String? helperId,
  });

  /// Clocks [helperId] in, in [by]'s name, at the server's time.
  Future<void> startShift({
    required String householdId,
    required String helperId,
    required String by,
  });

  /// Clocks an open shift out, in [by]'s name, at the server's time.
  Future<void> endShift({
    required String householdId,
    required String shiftId,
    required String by,
  });
}
