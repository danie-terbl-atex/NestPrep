import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/vault_document.dart';
import '../model/vault_grant.dart';
import '../model/vault_view.dart';
import 'vault_repository.dart';

final class FirestoreVaultRepository implements VaultRepository {
  FirestoreVaultRepository(this._firestore);

  static const vaultsPath = 'vaults';
  static const documentsPath = 'vaultDocuments';
  static const grantsPath = 'grants';
  static const viewsPath = 'views';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _vault(
    String householdId,
    String ownerMemberId,
  ) => _firestore
      .collection('households')
      .doc(householdId)
      .collection(vaultsPath)
      .doc(ownerMemberId);

  CollectionReference<VaultDocument> _documents(
    String householdId,
    String ownerMemberId,
  ) => typedCollection(
    _vault(householdId, ownerMemberId).collection(documentsPath),
    fromJson: (json) =>
        VaultDocument.fromJson(json).copyWith(ownerMemberId: ownerMemberId),
    toJson: (document) => document.toJson(),
  );

  CollectionReference<VaultGrant> _grants(
    String householdId,
    String ownerMemberId,
  ) => typedCollection(
    _vault(householdId, ownerMemberId).collection(grantsPath),
    fromJson: VaultGrant.fromJson,
    toJson: (grant) => grant.toJson(),
  );

  CollectionReference<VaultView> _views(
    String householdId,
    String ownerMemberId,
  ) => typedCollection(
    _vault(householdId, ownerMemberId).collection(viewsPath),
    fromJson: (json) =>
        VaultView.fromJson(json).copyWith(ownerMemberId: ownerMemberId),
    toJson: (view) => view.toJson(),
  );

  @override
  Stream<List<VaultDocument>> watchVault({
    required String householdId,
    required String ownerMemberId,
  }) => _documents(householdId, ownerMemberId)
      .orderBy('uploadedAt', descending: true)
      .limit(VaultRepository.documentLimit)
      .snapshots()
      .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<VaultGrant>> watchGrants({
    required String householdId,
    required String ownerMemberId,
  }) => _grants(householdId, ownerMemberId)
      .limit(VaultRepository.grantLimit)
      .snapshots()
      .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<bool> watchGrantTo({
    required String householdId,
    required String ownerMemberId,
    required String granteeUid,
  }) => _grants(householdId, ownerMemberId)
      .doc(granteeUid)
      .snapshots()
      .map((snapshot) => snapshot.exists)
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<VaultView>> watchViews({
    required String householdId,
    required String ownerMemberId,
  }) => _views(householdId, ownerMemberId)
      .orderBy('viewedAt', descending: true)
      .limit(VaultRepository.viewLimit)
      .snapshots()
      .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  String newDocumentId({
    required String householdId,
    required String ownerMemberId,
  }) => _documents(householdId, ownerMemberId).doc().id;

  @override
  Future<void> addDocument(VaultDocumentDraft draft) => _guarded(
    () => _documents(draft.householdId, draft.ownerMemberId)
        .doc(draft.documentId)
        .set(
          VaultDocument(
            id: draft.documentId,
            name: draft.name,
            contentType: draft.contentType,
            sizeBytes: draft.sizeBytes,
            uploadedBy: draft.uploadedBy,
            tags: draft.tags,
            expiresOn: draft.expiresOn,
          ),
        ),
  );

  @override
  Future<void> editDocument({
    required VaultDocument document,
    required String householdId,
    required String name,
    required List<String> tags,
    required CalendarDate? expiresOn,
  }) => _guarded(
    () => _documents(householdId, document.ownerMemberId)
        .doc(document.id)
        .update({'name': name, 'tags': tags, 'expiresOn': expiresOn?.iso}),
  );

  @override
  Future<void> removeDocument({
    required String householdId,
    required String ownerMemberId,
    required String documentId,
  }) => _guarded(
    () => _documents(householdId, ownerMemberId).doc(documentId).delete(),
  );

  @override
  Future<void> grant({
    required String householdId,
    required String ownerMemberId,
    required String granteeUid,
    required String granteeMemberId,
    required String grantedBy,
  }) => _guarded(
    () => _grants(householdId, ownerMemberId)
        .doc(granteeUid)
        .set(
          VaultGrant(
            id: granteeUid,
            memberId: granteeMemberId,
            grantedBy: grantedBy,
          ),
        ),
  );

  @override
  Future<void> revoke({
    required String householdId,
    required String ownerMemberId,
    required String granteeUid,
  }) => _guarded(
    () => _grants(householdId, ownerMemberId).doc(granteeUid).delete(),
  );

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
