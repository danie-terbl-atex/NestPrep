import 'dart:typed_data';

/// What the hub keeps on the phone itself so it works without a signal
/// (nanny-hub ADR-0007): the photos a carer needs in a hurry — the house
/// guide, the child cards, who may collect — and when they were last saved.
///
/// Firestore's own cache keeps the words; this keeps what Firestore cannot,
/// because Storage has no cache. It is per household, and a carer kept to
/// their shifts has it cleared when their shift's window closes.
abstract interface class OfflineShelf {
  /// The kept photo, or null when it was never saved here.
  Future<Uint8List?> readPhoto({
    required String householdId,
    required String photoId,
  });

  Future<bool> hasPhoto({required String householdId, required String photoId});

  Future<void> keepPhoto({
    required String householdId,
    required String photoId,
    required Uint8List jpeg,
  });

  /// When the hub was last saved for offline in full, or null.
  Future<DateTime?> savedAt(String householdId);

  Future<void> markSaved(String householdId, DateTime at);

  /// Everything kept for [householdId]: its photos and its saved time.
  Future<void> clear(String householdId);
}
