import 'package:freezed_annotation/freezed_annotation.dart';

part 'offline_copy.freezed.dart';
part 'offline_copy.g.dart';

/// One document kept on this phone (documents ADR-0007): where it came from,
/// what to call it, and how big it is. Stored only inside the encrypted
/// index of the phone's offline copies — never in Firestore — so its times
/// are ISO strings, not Timestamps.
@freezed
abstract class OfflineCopy with _$OfflineCopy {
  const factory OfflineCopy({
    required String householdId,

    /// The vault it came from, or null for a household document.
    String? ownerMemberId,
    required String documentId,
    required String name,
    required String contentType,
    required int sizeBytes,
    required DateTime savedAt,
  }) = _OfflineCopy;

  const OfflineCopy._();

  factory OfflineCopy.fromJson(Map<String, Object?> json) =>
      _$OfflineCopyFromJson(json);

  /// Unique on this phone: a document id alone is not, across households
  /// and vaults. Also the encrypted file's name.
  String get key =>
      [householdId, ownerMemberId ?? 'household', documentId].join('_');

  bool get isFromVault => ownerMemberId != null;

  bool get isImage => contentType.startsWith('image/');
}
