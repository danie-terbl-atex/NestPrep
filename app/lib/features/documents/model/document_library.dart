import 'document_folder.dart';
import 'household_document.dart';

/// What the documents screens render: the household's folders, and everything
/// filed in them, off **one** read of each collection.
///
/// Splitting the documents by folder here rather than querying per folder is
/// the grocery list's reasoning again — two queries over the same collection
/// disagree while a write is pending, and one listener cannot disagree with
/// itself. It is also the reason nothing here needs a composite index.
class DocumentLibrary {
  DocumentLibrary({
    required this.folders,
    required List<HouseholdDocument> documents,
  }) : _byFolder = _group(documents);

  final List<DocumentFolder> folders;
  final Map<String, List<HouseholdDocument>> _byFolder;

  static Map<String, List<HouseholdDocument>> _group(
    List<HouseholdDocument> documents,
  ) {
    final grouped = <String, List<HouseholdDocument>>{};
    for (final document in documents) {
      (grouped[document.folderId] ??= <HouseholdDocument>[]).add(document);
    }
    return grouped;
  }

  bool get isEmpty => folders.isEmpty;

  List<HouseholdDocument> inFolder(String folderId) =>
      _byFolder[folderId] ?? const [];

  int countIn(String folderId) => inFolder(folderId).length;

  DocumentFolder? folderById(String folderId) =>
      folders.where((folder) => folder.id == folderId).firstOrNull;

  HouseholdDocument? documentById(String documentId) {
    for (final documents in _byFolder.values) {
      for (final document in documents) {
        if (document.id == documentId) return document;
      }
    }
    return null;
  }
}
