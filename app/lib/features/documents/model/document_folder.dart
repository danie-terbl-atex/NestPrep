import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'document_folder.freezed.dart';
part 'document_folder.g.dart';

/// One shelf of the household's filing cabinet, at
/// `households/{id}/documentFolders/{folderId}` (documents ADR-0001).
///
/// Flat: a folder holds documents and never another folder. A document names
/// the folder it is in rather than nesting under it, so moving one is a field
/// and not a copy.
///
/// Folders are admin-managed, and deleting one is `deleteDocumentFolder` rather
/// than a client write — a rule cannot count what is still in it.
@freezed
abstract class DocumentFolder with _$DocumentFolder {
  const factory DocumentFolder({
    @JsonKey(includeToJson: false) required String id,
    required String name,

    /// The member profile that made it, not the account.
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _DocumentFolder;

  const DocumentFolder._();

  factory DocumentFolder.fromJson(Map<String, Object?> json) =>
      _$DocumentFolderFromJson(json);
}
