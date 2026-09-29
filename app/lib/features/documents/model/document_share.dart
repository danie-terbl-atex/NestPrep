import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/instant_converter.dart';
import '../../../shared/firestore/nullable_timestamp_converter.dart';

part 'document_share.freezed.dart';
part 'document_share.g.dart';

/// One link to one document, as the family sees it, at
/// `households/{h}/documentShares/{shareId}` (documents ADR-0006).
///
/// Written only by the Functions — made by `createDocumentShare`, stopped by
/// `revokeDocumentShare`, counted by the link itself, ended with its shift —
/// so the app reads it and never writes it. The link itself is not here: it
/// exists only on the phone that made it, once.
@freezed
abstract class DocumentShare with _$DocumentShare {
  const factory DocumentShare({
    @JsonKey(includeToJson: false) required String id,

    /// `household` for a folder's document, `vault` for a person's.
    required String scope,

    /// The vault it came from, or null for a household document.
    String? ownerMemberId,
    required String documentId,

    /// The document's name when the link was made.
    required String documentName,
    required String contentType,

    /// The member who made it, or null for an account with no profile.
    String? createdBy,
    required String createdByUid,
    @NullableTimestampConverter() DateTime? createdAt,

    /// When it stops working at the latest (`ENG-21`).
    @InstantConverter() required DateTime expiresAt,

    /// The nanny-hub shift it ends with, if it was made for one.
    String? shiftId,
    required bool hasPin,
    @Default(DocumentShare.active) String status,
    @Default(0) int openCount,
    @NullableTimestampConverter() DateTime? lastOpenedAt,
  }) = _DocumentShare;

  const DocumentShare._();

  factory DocumentShare.fromJson(Map<String, Object?> json) =>
      _$DocumentShareFromJson(json);

  static const active = 'active';
  static const vaultScope = 'vault';

  bool get isFromVault => scope == vaultScope;

  bool get isUntilShiftEnds => shiftId != null;

  /// Whether it would still open at [now]: active and not yet expired. A
  /// shift that has ended is the server's to know; the list follows it.
  bool isLiveAt(DateTime now) => status == active && expiresAt.isAfter(now);
}
