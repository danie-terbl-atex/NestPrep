/// Who is a child — the one profile write a client may not make itself,
/// because it is what the free tier counts: one child free, more with
/// premium (subscriptions ADR-0001). Rules cannot count, so the
/// `setChildProfile` Function does, in a transaction. A second child on a
/// free household is refused with `PremiumRequiredFailure`.
abstract interface class ChildProfileDirectory {
  Future<void> setIsChild({
    required String householdId,
    required String memberId,
    required bool isChild,
  });
}
