import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import 'document_limits.dart';

part 'household_document.freezed.dart';
part 'household_document.g.dart';

/// What a document *is*, at `households/{id}/documents/{documentId}`
/// (documents ADR-0001). The bytes are the Cloud Storage object of the same
/// name — deliberately the same string, so an orphan on either side is findable
/// by listing the other.
///
/// `contentType` and `sizeBytes` are here for the label a person reads. The
/// limits that matter are enforced on the bytes by `storage.rules`, because
/// that is the only place that can see them (`BE-03`).
@freezed
abstract class HouseholdDocument with _$HouseholdDocument {
  const factory HouseholdDocument({
    @JsonKey(includeToJson: false) required String id,

    /// The folder it is filed in. A document is always in exactly one.
    required String folderId,
    required String name,
    required String contentType,
    required int sizeBytes,

    /// The member profile that added it, not the account.
    required String uploadedBy,
    @ServerTimestampConverter() DateTime? uploadedAt,
  }) = _HouseholdDocument;

  const HouseholdDocument._();

  factory HouseholdDocument.fromJson(Map<String, Object?> json) =>
      _$HouseholdDocumentFromJson(json);

  /// Whether the app can render this itself, or has to hand it to the device.
  bool get isPreviewable => DocumentLimits.isPreviewable(contentType);
}
