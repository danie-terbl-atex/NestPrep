import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/handover_draft.dart';
import '../model/handover_entry.dart';
import '../model/nanny_limits.dart';
import '../model/shift.dart';
import '../model/shift_summary.dart';
import 'nanny_paths.dart';
import 'shift_repository.dart';

final class FirestoreShiftRepository implements ShiftRepository {
  FirestoreShiftRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _home(String householdId) =>
      _firestore.collection(NannyPaths.households).doc(householdId);

  CollectionReference<Map<String, dynamic>> _shifts(String householdId) =>
      _home(householdId).collection(NannyPaths.shifts);

  CollectionReference<Map<String, dynamic>> _entries(
    String householdId,
    String shiftId,
  ) => _shifts(householdId).doc(shiftId).collection(NannyPaths.entries);

  static Never _readOnly(Object _) =>
      throw UnsupportedError('written field by field');

  @override
  Stream<List<Shift>> watchOpenShifts(String householdId) => _list(
    typedCollection(
      _shifts(householdId),
      fromJson: Shift.fromJson,
      toJson: _readOnly,
    ).where('status', isEqualTo: Shift.open).limit(NannyLimits.openShiftListen),
  );

  @override
  Stream<Shift?> watchShift({
    required String householdId,
    required String shiftId,
  }) =>
      typedCollection(
            _shifts(householdId),
            fromJson: Shift.fromJson,
            toJson: _readOnly,
          )
          .doc(shiftId)
          .snapshots()
          .map((snapshot) => snapshot.data())
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<HandoverEntry>> watchEntries({
    required String householdId,
    required String shiftId,
  }) => _list(
    typedCollection(
      _entries(householdId, shiftId),
      fromJson: HandoverEntry.fromJson,
      toJson: _readOnly,
    ).orderBy('at').limit(NannyLimits.entryListen),
  );

  @override
  Stream<List<ShiftSummary>> watchSummaries(String householdId) => _list(
    typedCollection(
          _home(householdId).collection(NannyPaths.summaries),
          fromJson: ShiftSummary.fromJson,
          toJson: _readOnly,
        )
        .orderBy('endedAt', descending: true)
        .limit(NannyLimits.summaryListen),
  );

  Stream<List<T>> _list<T>(Query<T> query) => query
      .snapshots()
      .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<String> startShift({
    required String householdId,
    required String carerMemberId,
    required String startedBy,
  }) async {
    final shift = _shifts(householdId).doc();
    await _guarded(
      () => shift.set({
        'carerMemberId': carerMemberId,
        'startedBy': startedBy,
        'startedAt': FieldValue.serverTimestamp(),
        'endedAt': null,
        'endedBy': null,
        'status': Shift.open,
        'ticks': <String, bool>{},
      }),
    );
    return shift.id;
  }

  @override
  Future<void> setTick({
    required String householdId,
    required String shiftId,
    required String tickKey,
    required bool isTicked,
  }) => _guarded(
    // A field path, not a dotted string: the key holds a colon, and the path
    // is what keeps it one key rather than an address.
    () => _shifts(householdId).doc(shiftId).update({
      FieldPath(['ticks', tickKey]): isTicked ? true : FieldValue.delete(),
    }),
  );

  @override
  Future<void> addEntry({
    required String householdId,
    required String shiftId,
    required String byMemberId,
    required HandoverDraft draft,
  }) => _guarded(
    () => _entries(householdId, shiftId).add({
      ..._draftFields(draft),
      'byMemberId': byMemberId,
      'createdAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> updateEntry({
    required String householdId,
    required String shiftId,
    required String entryId,
    required HandoverDraft draft,
  }) => _guarded(
    () => _entries(householdId, shiftId).doc(entryId).update(_draftFields(draft)),
  );

  static Map<String, Object?> _draftFields(HandoverDraft draft) => {
    'kind': draft.kind.name,
    'note': draft.note,
    'mood': draft.mood?.name,
    'childIds': draft.childIds,
    'photoId': draft.photoId,
    'at': Timestamp.fromDate(draft.at.toUtc()),
  };

  @override
  Future<void> removeEntry({
    required String householdId,
    required String shiftId,
    required String entryId,
  }) => _guarded(() => _entries(householdId, shiftId).doc(entryId).delete());

  Future<void> _guarded(Future<Object?> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
