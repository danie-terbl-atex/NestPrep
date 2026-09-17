import '../model/grocery_item.dart';

/// What the groceries feature needs from Firestore. Both reads are bounded
/// (`BE-08`): one household's list is small, and the history is capped at the
/// window the chips are ranked from.
abstract interface class GroceryRepository {
  /// Everything still to buy, newest first.
  Stream<List<GroceryItem>> watchUnbought(String householdId);

  /// The most recently bought items, newest first. This one stream does two
  /// jobs: the last day of it is what the list shows struck through, and all of
  /// it is what the quick re-add chips are ranked from (groceries ADR-0001).
  Stream<List<GroceryItem>> watchRecentlyBought(String householdId);

  Future<void> add({
    required String householdId,
    required String name,
    String? quantity,
    required String addedBy,
  });

  /// Ticks or unticks. Ticking stamps the server's time and who did it;
  /// unticking clears both.
  Future<void> setBought({
    required String householdId,
    required String itemId,
    required bool isBought,
    required String memberId,
  });

  Future<void> rename({
    required String householdId,
    required String itemId,
    required String name,
    String? quantity,
  });

  Future<void> remove({required String householdId, required String itemId});

  /// How many bought items the history stream carries.
  static const historyLimit = 200;
}
