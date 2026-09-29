/// Who is a child — the one profile write a client may not make itself,
/// because it is what the free tier counts: one child free, more with
/// premium (subscriptions ADR-0001). Rules cannot count, so the
/// `setChildProfile` Function does, in a transaction. A second child on a
/// free household is refused with `PremiumRequiredFailure`.
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
