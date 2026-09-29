import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/nanny_limits.dart';
import '../model/pickup_change.dart';
import '../model/pickup_drafts.dart';
import '../model/pickup_person.dart';
import '../model/school_run.dart';
import 'nanny_hub_repository.dart';
import 'nanny_paths.dart';
import 'pickup_repository.dart';

final class FirestorePickupRepository implements PickupRepository {
  FirestorePickupRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _raw(
    String householdId,
    String path,
  ) => _firestore
      .collection(NannyPaths.households)
      .doc(householdId)
      .collection(path);

  CollectionReference<T> _typed<T>(
    String householdId,
    String path,
    T Function(Map<String, Object?> json) fromJson,
  ) => typedCollection(
    _raw(householdId, path),
    fromJson: fromJson,
    // Written field by field below, never as a whole model.
    toJson: (_) => throw UnsupportedError('written field by field'),
  );

  Stream<List<T>> _list<T>(Stream<QuerySnapshot<T>> snapshots) => snapshots
      .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<PickupPerson>> watchPeople(String householdId) => _list(
    _typed(
      householdId,
      NannyPaths.pickupPeople,
      PickupPerson.fromJson,
    ).limit(NannyLimits.pickupPeopleListen).snapshots(),
  );

  @override
  Stream<List<SchoolRun>> watchRuns(String householdId) => _list(
    _typed(
      householdId,
      NannyPaths.schoolRuns,
      SchoolRun.fromJson,
    ).limit(NannyLimits.schoolRunListen).snapshots(),
  );

  @override
  Stream<List<PickupChange>> watchChanges(
    String householdId, {
    required CalendarDate from,
  }) => _list(
    _typed(householdId, NannyPaths.pickupChanges, PickupChange.fromJson)
        .where('date', isGreaterThanOrEqualTo: from.iso)
        .orderBy('date')
        .limit(NannyLimits.pickupChangeListen)
        .snapshots(),
  );

  static Map<String, Object?> _personFields(
    PickupPersonDraft draft,
    String? photoId,
  ) => {
    'name': draft.name,
    'relationship': draft.relationship,
    'idNote': draft.idNote,
    'phone': draft.phone,
    'photoId': photoId,
    'childIds': draft.childIds.toList()..sort(),
  };

  @override
  Future<void> addPerson(
    AuthoredBy by,
    PickupPersonDraft draft, {
    String? photoId,
  }) => _guarded(
    () => _raw(by.householdId, NannyPaths.pickupPeople).add({
      ..._personFields(draft, photoId),
      'createdBy': by.memberId,
      'createdAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> updatePerson(
    String householdId,
    String personId,
    PickupPersonDraft draft, {
    String? photoId,
  }) => _guarded(
    () => _raw(
      householdId,
      NannyPaths.pickupPeople,
    ).doc(personId).update(_personFields(draft, photoId)),
  );

  @override
  Future<void> removePerson(String householdId, String personId) => _guarded(
    () => _raw(householdId, NannyPaths.pickupPeople).doc(personId).delete(),
  );

  @override
  Future<void> saveRun(AuthoredBy by, SchoolRunDraft draft) => _guarded(
    () => _raw(by.householdId, NannyPaths.schoolRuns)
        .doc(SchoolRun.idFor(draft.childId, draft.weekday))
        .set({
          'childId': draft.childId,
          'weekday': draft.weekday,
          'personId': draft.collector.personId,
          'memberId': draft.collector.memberId,
          'atMinute': draft.atMinute,
          'place': draft.place,
          'updatedBy': by.memberId,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
  );

  @override
  Future<void> removeRun(String householdId, String runId) => _guarded(
    () => _raw(householdId, NannyPaths.schoolRuns).doc(runId).delete(),
  );

  @override
  Future<void> saveChange(AuthoredBy by, PickupChangeDraft draft) => _guarded(
    () => _raw(by.householdId, NannyPaths.pickupChanges)
        .doc(PickupChange.idFor(draft.childId, draft.date))
        .set({
          'childId': draft.childId,
          'date': draft.date.iso,
          'personId': draft.collector.personId,
          'memberId': draft.collector.memberId,
          'atMinute': draft.atMinute,
          'note': draft.note,
          'updatedBy': by.memberId,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
  );

  @override
  Future<void> removeChange(String householdId, String changeId) => _guarded(
    () => _raw(householdId, NannyPaths.pickupChanges).doc(changeId).delete(),
  );

  Future<void> _guarded(Future<Object?> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
