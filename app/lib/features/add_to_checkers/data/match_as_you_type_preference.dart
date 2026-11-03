/// Whether the grocery add field shows the chosen shop's products while
/// somebody types (add-to-checkers ADR-0007), kept on this phone per
/// household beside the chosen shop.
abstract interface class MatchAsYouTypePreference {
  /// Null until somebody on this phone turns it on or off for [householdId].
  Future<bool?> readMatchAsYouType(String householdId);

  Future<void> writeMatchAsYouType(String householdId, {required bool isOn});
}
