import '../model/checkers_area.dart';

/// The city a household said it shops in, kept on this phone (not in
/// Firestore): it only steers which Checkers stores the product matches come
/// from, and no other member's phone needs it.
abstract interface class CheckersAreaPreference {
  /// Null until somebody on this phone chooses one for [householdId].
  Future<CheckersArea?> read(String householdId);

  Future<void> write(String householdId, CheckersArea area);
}
