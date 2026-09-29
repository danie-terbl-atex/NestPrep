import '../data/document_store.dart';
import '../data/vault_repository.dart';
import '../data/vault_store.dart';
import '../model/picked_document.dart';
import '../model/vault_upload_details.dart';
import 'upload_destination.dart';

/// A person's vault as an upload's destination (documents ADR-0002): the bytes
/// go under the owner's path, stamped with the account adding them, and the
/// row carries the name, tags and expiry somebody chose before saving.
final class VaultUploadDestination
    implements UploadDestination<VaultUploadDetails> {
  const VaultUploadDestination({
    required this._repository,
    required this._store,
    required this.householdId,
    required this.memberId,
    required this.viewerUid,
  });

  final VaultRepository _repository;
  final VaultStore _store;
  final String householdId;
  final String memberId;
  final String viewerUid;

  @override
  String mintId(VaultUploadDetails details) => _repository.newDocumentId(
    householdId: householdId,
    ownerMemberId: details.ownerMemberId,
  );

  @override
  DocumentUpload send(
    String documentId,
    PickedDocument file,
    VaultUploadDetails details,
  ) => _store.upload(
    householdId: householdId,
    ownerMemberId: details.ownerMemberId,
    documentId: documentId,
    uploaderUid: viewerUid,
    file: file,
  );

  @override
  Future<void> record(
    String documentId,
    PickedDocument file,
    VaultUploadDetails details,
  ) => _repository.addDocument(
    VaultDocumentDraft(
      householdId: householdId,
      ownerMemberId: details.ownerMemberId,
      documentId: documentId,
      name: details.name,
      contentType: file.contentType,
      sizeBytes: file.sizeBytes,
      uploadedBy: memberId,
      tags: details.tags,
      expiresOn: details.expiresOn,
    ),
  );

  @override
  Future<void> discard(String documentId, VaultUploadDetails details) =>
      _store.remove(
        householdId: householdId,
        ownerMemberId: details.ownerMemberId,
        documentId: documentId,
      );
}
