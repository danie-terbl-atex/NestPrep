/// The referrals callables (subscriptions ADR-0002). A code is made, and a
/// code is entered, only on the server — no phone picks its code or moves a
/// referral along. Each refusal arrives as an `AppFailure` (`BE-04`).
abstract interface class ReferralDirectory {
  /// The household's own code, made the first time it is asked for and the
  /// same ever after.
  Future<String> ensureCode(String householdId);

  /// Enters another family's [code] for this household. Answers the moment
  /// by which the household has to become a family for both to get a month.
  Future<DateTime> redeem({required String householdId, required String code});
}
