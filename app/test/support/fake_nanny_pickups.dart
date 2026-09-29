import 'dart:async';

import 'package:nestprep/features/nanny_hub/data/nanny_hub_repository.dart';
import 'package:nestprep/features/nanny_hub/data/pickup_repository.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_change.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_drafts.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_person.dart';
import 'package:nestprep/features/nanny_hub/model/school_run.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// Pickups driven by hand: three live reads a test answers when it chooses,
/// and a record of every write, so a test asserts what a tap asked the
/// backend to do (`FE-20`).
final class FakePickupRepository implements PickupRepository {
  final people = StreamController<List<PickupPerson>>.broadcast();
  final runs = StreamController<List<SchoolRun>>.broadcast();
  final changes = StreamController<List<PickupChange>>.broadcast();

  /// Set to make the next writes fail the way a rules denial does.
  AppFailure? failWritesWith;

  /// Every write, in order, as `(method, arguments)`.
  final writes = <(String, Map<String, Object?>)>[];

  /// The date the changes were asked from.
  CalendarDate? changesFrom;

  void emitAll({
    List<PickupPerson> peopleList = const [],
    List<SchoolRun> runList = const [],
    List<PickupChange> changeList = const [],
  }) {
    people.add(peopleList);
    runs.add(runList);
    changes.add(changeList);
  }

  Future<void> close() async {
    await people.close();
    await runs.close();
    await changes.close();
  }

  Future<void> _write(String method, Map<String, Object?> arguments) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    writes.add((method, arguments));
  }

  @override
  Stream<List<PickupPerson>> watchPeople(String householdId) => people.stream;

  @override
  Stream<List<SchoolRun>> watchRuns(String householdId) => runs.stream;

  @override
  Stream<List<PickupChange>> watchChanges(
    String householdId, {
    required CalendarDate from,
  }) {
    changesFrom = from;
    return changes.stream;
  }

  @override
  Future<void> addPerson(
    AuthoredBy by,
    PickupPersonDraft draft, {
    String? photoId,
  }) => _write('addPerson', {
    'memberId': by.memberId,
    'draft': draft,
    'photoId': photoId,
  });

  @override
  Future<void> updatePerson(
    String householdId,
    String personId,
    PickupPersonDraft draft, {
    String? photoId,
  }) => _write('updatePerson', {
    'personId': personId,
    'draft': draft,
    'photoId': photoId,
  });

  @override
  Future<void> removePerson(String householdId, String personId) =>
      _write('removePerson', {'personId': personId});

  @override
  Future<void> saveRun(AuthoredBy by, SchoolRunDraft draft) =>
      _write('saveRun', {'memberId': by.memberId, 'draft': draft});

  @override
  Future<void> removeRun(String householdId, String runId) =>
      _write('removeRun', {'runId': runId});

  @override
  Future<void> saveChange(AuthoredBy by, PickupChangeDraft draft) =>
      _write('saveChange', {'memberId': by.memberId, 'draft': draft});

  @override
  Future<void> removeChange(String householdId, String changeId) =>
      _write('removeChange', {'changeId': changeId});
}
