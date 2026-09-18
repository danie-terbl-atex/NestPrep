import '../model/document_folder.dart';
import '../model/household_document.dart';

/// The metadata half of the documents feature: what folders there are, and what
/// is filed in them. The bytes are `DocumentStore`'s, and deleting a folder is
/// `DocumentDirectory`'s, because a rule cannot count what is still in one.
///
/// Both reads are whole-collection and bounded, and the split by folder happens
/// on the client (documents ADR-0001): one listener per collection cannot
/// disagree with itself while a write is pending, and nothing here needs a
/// composite index.
abstract interface class DocumentRepository {
  Stream<List<DocumentFolder>> watchFolders(String householdId);

  Stream<List<HouseholdDocument>> watchDocuments(String householdId);

  /// The id the bytes will be stored under, minted before the upload starts.
  /// The Storage object's name **is** this id, which is what makes an orphan on
  /// either side findable by listing the other.
  String newDocumentId(String householdId);

  Future<void> createFolder({
    required String householdId,
    required String name,
    required String createdBy,
  });

  Future<void> renameFolder({
    required String householdId,
    required String folderId,
    required String name,
  });

  /// Writes the row for bytes that are already stored. Called after the upload
  /// and never before it (`BE-07`).
  Future<void> addDocument({
    required String householdId,
    required String documentId,
    required String folderId,
    required String name,
    required String contentType,
    required int sizeBytes,
    required String uploadedBy,
  });

  Future<void> editDocument({
    required String householdId,
    required String documentId,
    required String name,
    required String folderId,
  });

  /// Removes the row. The bytes go first (`BE-07`).
  Future<void> removeDocument({
    required String householdId,
    required String documentId,
  });

  /// How much of a household's filing cabinet is read at once. Bounded so a bug
  /// cannot make either listener unbounded (`BE-08`); far above what a
  /// household actually keeps.
  static const folderLimit = 50;
  static const documentLimit = 300;
}
