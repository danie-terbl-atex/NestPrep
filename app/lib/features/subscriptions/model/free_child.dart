/// Which child the free tier plans for (lunch-box ADR-0009), as
/// `setChildProfile` records it in `entitlement/freeChild`. A household with
/// no record yet has none of these: it has not marked a child since the
/// record began, and is not held to one.
final class FreeChild {
  const FreeChild(this.memberId);

  /// Null when the record names nobody — the household has no child.
  final String? memberId;

  /// Parses the stored document: only a non-empty string names a child.
  factory FreeChild.fromStored(Object? memberId) =>
      FreeChild(memberId is String && memberId.isNotEmpty ? memberId : null);
}
