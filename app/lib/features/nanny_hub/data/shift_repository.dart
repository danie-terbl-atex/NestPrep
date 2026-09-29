import '../model/handover_draft.dart';
import '../model/handover_entry.dart';
import '../model/shift.dart';
import '../model/shift_summary.dart';

/// Shifts, their handover log and their summaries, as Firestore holds them
/// (nanny-hub ADR-0002). Ending a shift is not here: it writes the summary
/// too, so it is `ShiftDirectory`'s, a Cloud Function.
abstract interface class ShiftRepository {
  /// Shifts nobody has ended — the carer's own, to resume, and anybody's, for
  /// a parent to see who is on.
  Stream<List<Shift>> watchOpenShifts(String householdId);

  /// One shift, live; null once it is gone or was never there.
  Stream<Shift?> watchShift({
    required String householdId,
    required String shiftId,
  });

  /// The shift's log in the order it happened.
  Stream<List<HandoverEntry>> watchEntries({
    required String householdId,
    required String shiftId,
  });

  /// The newest summaries first.
  Stream<List<ShiftSummary>> watchSummaries(String householdId);

  /// Starts a shift for [carerMemberId], stamped as started by [startedBy],
  /// and answers its id.
  Future<String> startShift({
    required String householdId,
    required String carerMemberId,
    required String startedBy,
  });

  /// Ticks or unticks one checklist item on this shift only.
  Future<void> setTick({
    required String householdId,
    required String shiftId,
    required String tickKey,
    required bool isTicked,
  });

  Future<void> addEntry({
    required String householdId,
    required String shiftId,
    required String byMemberId,
    required HandoverDraft draft,
  });

  Future<void> updateEntry({
    required String householdId,
    required String shiftId,
    required String entryId,
    required HandoverDraft draft,
  });

  Future<void> removeEntry({
    required String householdId,
    required String shiftId,
    required String entryId,
  });
}
