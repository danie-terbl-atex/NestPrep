import '../data/document_store.dart';
import '../model/picked_document.dart';

/// Where an upload lands, as the four steps `DocumentUploadRunner` takes in
/// order: mint the id, send the bytes, record the row, and — if the row cannot
/// be written — take the bytes away again (`BE-07`, documents ADR-0001).
///
/// The household's folders and the personal vaults are two destinations for
/// one runner, so the order that keeps bytes and rows findable is written once
/// (`ENG-01`). [T] is what the destination needs besides the file: a folder id,
/// or a vault's owner, name, tags and expiry.
abstract interface class UploadDestination<T> {
  String mintId(T details);

  DocumentUpload send(String documentId, PickedDocument file, T details);

  Future<void> record(String documentId, PickedDocument file, T details);

  Future<void> discard(String documentId, T details);
}
