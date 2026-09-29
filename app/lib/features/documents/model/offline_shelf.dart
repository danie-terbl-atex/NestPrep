import 'offline_copy.dart';

/// Everything kept on this phone for one household, and how much room it
/// takes (documents ADR-0007).
class OfflineShelf {
  const OfflineShelf(this.copies);

  /// At most this many copies per account on a phone, each at most the
  /// 20 MiB `storage.rules` allows — so never more than 400 MiB.
  static const maxCopies = 20;

  /// Newest first.
  final List<OfflineCopy> copies;

  bool get isEmpty => copies.isEmpty;

  bool get isFull => copies.length >= maxCopies;

  int get totalBytes => copies.fold(0, (sum, copy) => sum + copy.sizeBytes);

  bool holds({required String? ownerMemberId, required String documentId}) =>
      copies.any(
        (copy) =>
            copy.documentId == documentId &&
            copy.ownerMemberId == ownerMemberId,
      );
}
