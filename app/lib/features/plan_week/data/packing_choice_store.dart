import '../model/packing_preference.dart';

/// The brief's packing choices, kept on this phone per household (not in
/// Firestore): they only steer this parent's plan, and the next visit opens
/// with them.
abstract interface class PackingChoiceStore {
  /// Null until somebody on this phone chooses for [householdId], or when
  /// what is kept cannot be read.
  Future<PackingChoice?> read(String householdId);

  Future<void> write(String householdId, PackingChoice choice);
}
