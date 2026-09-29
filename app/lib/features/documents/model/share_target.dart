/// The one document a link is for (documents ADR-0006): where it is, and what
/// the sheet says about it.
class ShareTarget {
  const ShareTarget({
    required this.householdId,
    required this.ownerMemberId,
    required this.documentId,
    required this.name,
    required this.tags,
  });

  final String householdId;

  /// The vault it is in, or null for a household document.
  final String? ownerMemberId;
  final String documentId;
  final String name;
  final List<String> tags;
}
