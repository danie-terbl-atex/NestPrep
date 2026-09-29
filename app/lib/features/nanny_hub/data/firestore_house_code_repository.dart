import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/house_code.dart';
import '../model/nanny_limits.dart';
import 'house_code_repository.dart';
import 'nanny_hub_repository.dart';
import 'nanny_paths.dart';

final class FirestoreHouseCodeRepository implements HouseCodeRepository {
  FirestoreHouseCodeRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _codes(String householdId) =>
      _firestore
          .collection(NannyPaths.households)
          .doc(householdId)
          .collection(NannyPaths.secrets);

  @override
  Future<List<HouseCode>> fetch(String householdId) async {
    try {
      final snapshot =
          await typedCollection(
                _codes(householdId),
                fromJson: HouseCode.fromJson,
                toJson: (_) => throw UnsupportedError('written field by field'),
              )
              .orderBy('createdAt')
              .limit(NannyLimits.secretListen)
              // Never the cache: a code is shown only while the server still
              // says the window is open (nanny-hub ADR-0006).
              .get(const GetOptions(source: Source.server));
      return [for (final doc in snapshot.docs) doc.data()];
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  @override
  Future<void> add(AuthoredBy by, HouseCodeDraft draft) => _guarded(
    () => _codes(by.householdId).add({
      ..._fields(draft),
      'createdBy': by.memberId,
      'createdAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> update(
    String householdId,
    String codeId,
    HouseCodeDraft draft,
  ) => _guarded(() => _codes(householdId).doc(codeId).update(_fields(draft)));

  @override
  Future<void> remove(String householdId, String codeId) =>
      _guarded(() => _codes(householdId).doc(codeId).delete());

  static Map<String, Object?> _fields(HouseCodeDraft draft) => {
    'label': draft.label,
    'value': draft.value,
    'note': draft.note,
  };

  Future<void> _guarded(Future<Object?> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
