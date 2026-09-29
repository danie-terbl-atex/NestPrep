import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/time/calendar_date.dart';
import 'document_limits.dart';

part 'vault_document.freezed.dart';
part 'vault_document.g.dart';

/// One paper in a member's personal vault, at
/// `households/{h}/vaults/{memberId}/vaultDocuments/{documentId}` (documents
/// ADR-0002). Its bytes are the Storage object of the same id under the same
/// member.
///
/// The owner is the path, never a stored field — so `ownerMemberId` is set by
/// the repository from where the row was read, and never written back.
@freezed
abstract class VaultDocument with _$VaultDocument {
  const factory VaultDocument({
    @JsonKey(includeToJson: false) required String id,
    @JsonKey(includeToJson: false, includeFromJson: false)
    @Default('')
    String ownerMemberId,
    required String name,
    required String contentType,
    required int sizeBytes,

    /// The member profile that added it — the owner, or an admin filing it
    /// for a child.
    required String uploadedBy,
    @ServerTimestampConverter() DateTime? uploadedAt,
    @Default(<String>[]) List<String> tags,

    /// The day it stops being valid, in the household's zone (`ENG-21`).
    @NullableCalendarDateConverter() CalendarDate? expiresOn,
  }) = _VaultDocument;

  const VaultDocument._();

  factory VaultDocument.fromJson(Map<String, Object?> json) =>
      _$VaultDocumentFromJson(json);

  /// Whether the app renders it as a picture; everything else is a PDF, which
  /// the app renders page by page itself (documents ADR-0004).
  bool get isImage => DocumentLimits.isPreviewable(contentType);
}
