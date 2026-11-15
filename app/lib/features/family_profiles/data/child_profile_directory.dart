/// Who is a child — the one profile write a client may not make itself: the
/// `setChildProfile` Function writes it with the parent's consent, in one
/// transaction.
///
/// Marking a child who has no parent's consent on record carries the version
/// of the privacy policy the parent just agreed to; without it the Function
/// refuses with `guardianConsentRequired` (accounts ADR-0005).
abstract interface class ChildProfileDirectory {
  Future<void> setIsChild({
    required String householdId,
    required String memberId,
    required bool isChild,
    int? guardianConsentVersion,
  });
}
