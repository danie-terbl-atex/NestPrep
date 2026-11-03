import '../model/lunch_variety.dart';

/// The variety choice, kept on this phone per household (not in Firestore):
/// it only steers this parent's fills (lunch-box ADR-0028).
abstract interface class LunchVarietyStore {
  /// Null until somebody on this phone chooses for [householdId], or when
  /// what is kept cannot be read.
  Future<LunchVariety?> read(String householdId);

  Future<void> write(String householdId, LunchVariety variety);
}
