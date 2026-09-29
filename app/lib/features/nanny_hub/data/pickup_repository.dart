import '../../../shared/time/calendar_date.dart';
import '../model/pickup_change.dart';
import '../model/pickup_drafts.dart';
import '../model/pickup_person.dart';
import '../model/school_run.dart';
import 'nanny_hub_repository.dart';

/// Who may collect the children, and the school-run week, as Firestore holds
/// them (nanny-hub ADR-0005). Every read is bounded (`BE-08`); only family
/// writes, which the rules enforce — this layer only names who is writing
/// (`BE-03`). Drafts arrive already tidied by the controller.
abstract interface class PickupRepository {
  Stream<List<PickupPerson>> watchPeople(String householdId);
  Stream<List<SchoolRun>> watchRuns(String householdId);

  /// Changes from [from] on, soonest first — a change in the past is history.
  Stream<List<PickupChange>> watchChanges(
    String householdId, {
    required CalendarDate from,
  });

  Future<void> addPerson(
    AuthoredBy by,
    PickupPersonDraft draft, {
    String? photoId,
  });

  Future<void> updatePerson(
    String householdId,
    String personId,
    PickupPersonDraft draft, {
    String? photoId,
  });

  Future<void> removePerson(String householdId, String personId);

  /// Sets the child's run on that weekday, replacing whatever was there.
  Future<void> saveRun(AuthoredBy by, SchoolRunDraft draft);

  Future<void> removeRun(String householdId, String runId);

  /// Sets the change for that child on that date, replacing any other.
  Future<void> saveChange(AuthoredBy by, PickupChangeDraft draft);

  Future<void> removeChange(String householdId, String changeId);
}
