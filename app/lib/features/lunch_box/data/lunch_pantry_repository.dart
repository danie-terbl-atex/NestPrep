import '../model/lunch_packed_day.dart';
import '../model/lunch_pantry_entry.dart';
import '../model/lunch_week.dart';

/// The household's pantry as Firestore holds it (lunch-box ADR-0006): one
/// entry per library item, and a record per box marked packed. Writes the
/// rules refuse — a pantry below zero, a box packed twice — arrive as
/// `PermissionDeniedFailure`.
abstract interface class LunchPantryRepository {
  /// As many entries as the library can hold items.
  static const entryLimit = 400;

  /// Five school days for up to thirteen children.
  static const packedLimit = 70;

  Stream<List<LunchPantryEntry>> watchPantry(String householdId);

  /// Every box marked packed in [week], for every child.
  Stream<List<LunchPackedDay>> watchPacked(String householdId, LunchWeek week);

  /// Sets how many boxes' worth of [itemId] is in the house, adding it to
  /// the pantry if it was not there.
  Future<void> setPortions({
    required String householdId,
    required String itemId,
    required int portions,
    required String by,
  });

  Future<void> remove({required String householdId, required String itemId});

  /// Records [day] as packed and, in the same batch, takes [takeFrom]'s
  /// counts out of those pantry entries.
  Future<void> markPacked({
    required String householdId,
    required LunchPackedDay day,
    required Map<String, int> takeFrom,
  });

  /// Deletes [day]'s record and gives [giveBack]'s counts back.
  Future<void> unmarkPacked({
    required String householdId,
    required LunchPackedDay day,
    required Map<String, int> giveBack,
  });
}
