import '../model/lunch_favourite.dart';
import '../model/lunch_feedback.dart';
import '../model/lunch_item.dart';
import '../model/lunch_pick.dart';
import '../model/lunch_plan.dart';
import '../model/lunch_prep.dart';
import '../model/lunch_week.dart';

/// Lunch boxes as Firestore holds them (lunch-box ADR-0001): the household's
/// library, one plan per child per week, go-to boxes, and each week's prep
/// ticks. Every write names only the fields it moves, so two people packing
/// two days at once never overwrite each other.
///
/// A write the rules refuse — an allergen in a child's box, a nut for a
/// nut-free child — arrives as `PermissionDeniedFailure`.
abstract interface class LunchRepository {
  /// More than a household's library could grow to in a school career.
  static const itemLimit = 400;

  /// Nine weeks (this one and eight back) for up to thirteen children.
  static const planLimit = 120;

  static const favouriteLimit = 200;

  Stream<List<LunchItem>> watchItems(String householdId);

  /// Every child's plan for the weeks from [from] to [to], both included —
  /// the week on screen and the history its suggestions learn from, in one
  /// listener (`BE-08`).
  Stream<List<LunchPlan>> watchPlans(
    String householdId, {
    required LunchWeek from,
    required LunchWeek to,
  });

  /// One child's plan for one week, or an empty one — what a kid's tablet
  /// reads, asking for exactly the document its `own` grant opens.
  Stream<LunchPlan> watchPlan(
    String householdId, {
    required String childId,
    required LunchWeek week,
  });

  Stream<List<LunchFavourite>> watchFavourites(String householdId);

  Stream<LunchPrep> watchPrep(String householdId, LunchWeek week);

  /// Writes the starter library. The ids are fixed, so a second device
  /// seeding at the same moment writes the same documents.
  Future<void> seedItems(String householdId, List<LunchItem> items);

  /// Adds [item] and returns its id, or the id of the item the household
  /// already has by that name in that slot.
  Future<String> addItem(String householdId, LunchItem item);

  /// Changes what an item is called, contains, or how it is prepped.
  Future<void> updateItem(String householdId, LunchItem item);

  Future<void> setItemArchived({
    required String householdId,
    required String itemId,
    required bool archived,
  });

  /// Fills or clears slots of one child's week. A null pick clears its slot.
  /// Creates the plan on its first pick.
  Future<void> setPicks({
    required String householdId,
    required String childId,
    required LunchWeek week,
    required Map<String, LunchPick?> picks,
  });

  /// Records what came home on [isoWeekday], or with null takes it back.
  Future<void> setFeedback({
    required String householdId,
    required String childId,
    required LunchWeek week,
    required int isoWeekday,
    required LunchFeedback? feedback,
  });

  /// Returns the new favourite's id.
  Future<String> addFavourite(String householdId, LunchFavourite favourite);

  Future<void> deleteFavourite({
    required String householdId,
    required String favouriteId,
  });

  Future<void> setPrepDone({
    required String householdId,
    required LunchWeek week,
    required String itemId,
    required bool done,
  });
}
