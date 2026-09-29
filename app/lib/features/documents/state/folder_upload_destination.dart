import '../data/document_repository.dart';
import '../data/document_store.dart';
import '../model/picked_document.dart';
import 'upload_destination.dart';

/// A household folder as an upload's destination: the details are the folder
/// id, and the row is named after the file (documents ADR-0001).
final class FolderUploadDestination implements UploadDestination<String> {
  const FolderUploadDestination({
    required this._repository,
    required this._store,
    required this.householdId,
    required this.memberId,
    required this.viewerUid,
  });

  final DocumentRepository _repository;
  final DocumentStore _store;
  final String householdId;
  final String memberId;
  final String viewerUid;

  @override
  String mintId(String folderId) => _repository.newDocumentId(householdId);

  @override
  DocumentUpload send(
    String documentId,
    PickedDocument file,
    String folderId,
  ) => _store.upload(
    householdId: householdId,
    documentId: documentId,
    uploaderUid: viewerUid,
    file: file,
  );

  @override
  Future<void> record(
    String documentId,
    PickedDocument file,
    String folderId,
  ) => _repository.addDocument(
    householdId: householdId,
    documentId: documentId,
    folderId: folderId,
    name: file.name,
    contentType: file.contentType,
    sizeBytes: file.sizeBytes,
    uploadedBy: memberId,
  );

  @override
  Future<void> discard(String documentId, String folderId) =>
      _store.remove(householdId: householdId, documentId: documentId);
}
