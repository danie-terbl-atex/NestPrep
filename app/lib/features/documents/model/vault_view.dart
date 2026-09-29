import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'vault_view.freezed.dart';
part 'vault_view.g.dart';

/// One line of a vault's view log, at
/// `households/{h}/vaults/{memberId}/views/{id}` (documents ADR-0003).
///
/// Written only by `openVaultDocument`, in the same batch as the ticket the
/// bytes need, so it is evidence rather than a courtesy. Read-only here — the
/// app has no way to write, edit or delete one, and neither do the rules.
@freezed
abstract class VaultView with _$VaultView {
  const factory VaultView({
    @JsonKey(includeToJson: false) required String id,

    /// The vault it belongs to, from the path; never stored.
    @JsonKey(includeToJson: false, includeFromJson: false)
    @Default('')
    String ownerMemberId,
    required String documentId,

    /// The name when it was opened; a later rename does not rewrite history.
    required String documentName,

    /// Who opened it, or null for an account with no profile of its own —
    /// and for somebody who opened it through a shared link.
    String? viewerMemberId,

    /// The shared link it was opened through, if it was (documents
    /// ADR-0006). Absent on every entry written before links (`BE-10`).
    String? shareId,
    @ServerTimestampConverter() DateTime? viewedAt,
  }) = _VaultView;

  const VaultView._();

  factory VaultView.fromJson(Map<String, Object?> json) =>
      _$VaultViewFromJson(json);

  bool get isThroughSharedLink => shareId != null;
}
