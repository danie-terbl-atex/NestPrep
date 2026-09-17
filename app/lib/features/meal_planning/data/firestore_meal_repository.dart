import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../../../shared/text/normalised_name.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/meal.dart';
import '../model/week_plan.dart';
import 'meal_repository.dart';

final class FirestoreMealRepository implements MealRepository {
  FirestoreMealRepository(this._firestore);

  static const householdsPath = 'households';
  static const mealsPath = 'meals';
  static const plansPath = 'mealPlans';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _household(String householdId) =>
      _firestore.collection(householdsPath).doc(householdId);

  CollectionReference<Meal> _meals(String householdId) => typedCollection(
    _household(householdId).collection(mealsPath),
    fromJson: Meal.fromJson,
    toJson: (meal) => meal.toJson(),
  );

  CollectionReference<WeekPlan> _plans(String householdId) => typedCollection(
    _household(householdId).collection(plansPath),
    fromJson: WeekPlan.fromJson,
    toJson: (plan) => plan.toJson(),
  );

  @override
  Stream<List<Meal>> watchMeals(String householdId) =>
      _meals(householdId)
          .orderBy('name')
          .limit(MealRepository.mealLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<WeekPlan> watchWeek(String householdId, CalendarDate monday) =>
      _plans(householdId)
          .doc(monday.iso)
          .snapshots()
          .map((snapshot) => snapshot.data() ?? WeekPlan.empty(monday))
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<WeekPlan> readWeek(String householdId, CalendarDate monday) async {
    try {
      final snapshot = await _plans(householdId).doc(monday.iso).get();
      return snapshot.data() ?? WeekPlan.empty(monday);
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  @override
  Future<String> addMeal({
    required String householdId,
    required String name,
    required String addedBy,
  }) async {
    try {
      // The library is what has been typed before, deduplicated by a normalised
      // name (meal-planning ADR-0001) — so typing "spaghetti" again picks the
      // household's existing Spaghetti rather than making a second one.
      final existing = await _meals(householdId)
          .where('nameKey', isEqualTo: normalisedName(name))
          .limit(1)
          .get();
      final found = existing.docs.firstOrNull;
      if (found != null) return found.id;

      final document = _meals(householdId).doc();
      await document.set(
        Meal.named(id: document.id, name: name, addedBy: addedBy),
      );
      return document.id;
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  @override
  Future<void> renameMeal({
    required String householdId,
    required String mealId,
    required String name,
  }) => _guarded(
    () =>
        _meals(householdId)
            .doc(mealId)
            .update({'name': name, 'nameKey': normalisedName(name)}),
  );

  @override
  Future<void> deleteMeal({
    required String householdId,
    required String mealId,
    required List<CalendarDate> weeksToClear,
  }) => _guarded(() async {
    // Deleting a meal clears the slots that used it (meal-planning ADR-0001).
    // One batch, so a plan never points at a meal that is gone.
    final batch = _firestore.batch();
    for (final monday in weeksToClear) {
      final plan = await readWeek(householdId, monday);
      final keys = plan.slotsUsing(mealId);
      if (keys.isEmpty) continue;
      batch.update(_plans(householdId).doc(monday.iso), {
        for (final key in keys) 'slots.$key': FieldValue.delete(),
      });
    }
    batch.delete(_meals(householdId).doc(mealId));
    await batch.commit();
  });

  @override
  Future<void> setSlot({
    required String householdId,
    required CalendarDate monday,
    required String slotKey,
    required String mealId,
  }) => setSlots(
    householdId: householdId,
    monday: monday,
    slots: {slotKey: mealId},
  );

  @override
  Future<void> setSlots({
    required String householdId,
    required CalendarDate monday,
    required Map<String, String> slots,
  }) => _guarded(
    () => _plans(householdId)
        .doc(monday.iso)
        .set(
          WeekPlan(id: monday.iso, slots: slots),
          SetOptions(
            // Only the slots named here move, so two people filling different days
            // at the same time do not overwrite each other.
            mergeFields: [for (final key in slots.keys) 'slots.$key'],
          ),
        ),
  );

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
