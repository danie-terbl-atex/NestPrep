import '../model/grocery_item.dart';
import '../model/grocery_plan_changes.dart';
import '../model/grocery_plan_settings.dart';

/// What the groceries feature needs from Firestore.
///
/// **One read, split on the client.** Two queries over the same collection —
/// one for unbought, one for bought — disagree while a write is still pending:
/// the item shows twice, or not at all, until the network catches up. One
/// listener cannot disagree with itself. It is bounded (`BE-08`) and it is also
/// half the reads.
abstract interface class GroceryRepository {
  /// The household's list, newest first: what is still to buy, what has been
  /// bought, and the history the quick re-add chips are ranked from
  /// (groceries ADR-0001).
  Stream<List<GroceryItem>> watchItems(String householdId);

  /// A line a person typed. What the plans — or the pantry — put on the list
  /// goes through [applyPlanChanges] instead, and says where it came from.
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

  /// Edits an item's name **and** its quantity — both are written, so this is
  /// an edit rather than only a rename. An item the plans put there becomes
  /// the editor's: its source fields are cleared in the same write, so the
  /// plans leave it alone from then on (groceries ADR-0002).
  ///
  /// [quantity] is `required` while still nullable on purpose. Writing it
  /// unconditionally is right — clearing a quantity has to be possible — but
  /// when it was merely optional, omitting it silently erased whatever was
  /// there. Nullable-and-required makes a caller say which it means.
  Future<void> rename({
    required String householdId,
    required String itemId,
    required String name,
    required String? quantity,
  });

  Future<void> remove({required String householdId, required String itemId});

  /// Writes what the week's plans change on the list — new items, refreshed
  /// amounts, items no plan asks for now — in one batch, so a half-applied
  /// update is never on anybody's screen (groceries ADR-0002, `BE-07`).
  Future<void> applyPlanChanges({
    required String householdId,
    required GroceryPlanChanges changes,
    required String memberId,
  });

  /// The household's keep-in-step switch and staples; [GroceryPlanSettings.empty]
  /// until somebody sets either.
  Stream<GroceryPlanSettings> watchPlanSettings(String householdId);

  Future<void> setKeepInStep({
    required String householdId,
    required bool keepInStep,
    required String memberId,
  });

  /// Marks a normalised name *usually in the house*, or takes the mark off.
  Future<void> setStaple({
    required String householdId,
    required String key,
    required bool isStaple,
    required String memberId,
  });

  /// How much of a household's list is read at once. Bounded so a bug cannot
  /// make it unbounded; far above what a household actually has.
  static const itemLimit = 200;
}
