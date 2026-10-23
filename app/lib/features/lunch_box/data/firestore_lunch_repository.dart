import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/lunch_favourite.dart';
import '../model/lunch_feedback.dart';
import '../model/lunch_item.dart';
import '../model/lunch_pick.dart';
import '../model/lunch_plan.dart';
import '../model/lunch_prep.dart';
import '../model/lunch_week.dart';
import 'lunch_repository.dart';

final class FirestoreLunchRepository implements LunchRepository {
  FirestoreLunchRepository(this._firestore);

  static const householdsPath = 'households';
  static const itemsPath = 'lunchItems';
  static const plansPath = 'lunchPlans';
  static const favouritesPath = 'lunchFavourites';
  static const prepPath = 'lunchPrep';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _household(String householdId) =>
      _firestore.collection(householdsPath).doc(householdId);

  CollectionReference<LunchItem> _items(String householdId) => typedCollection(
    _household(householdId).collection(itemsPath),
    fromJson: LunchItem.fromJson,
    toJson: (item) => item.toJson(),
  );

  CollectionReference<LunchPlan> _plans(String householdId) => typedCollection(
    _household(householdId).collection(plansPath),
    fromJson: LunchPlan.fromJson,
    toJson: (plan) => plan.toJson(),
  );

  CollectionReference<LunchFavourite> _favourites(String householdId) =>
      typedCollection(
        _household(householdId).collection(favouritesPath),
        fromJson: LunchFavourite.fromJson,
        toJson: (favourite) => favourite.toJson(),
      );

  @override
  Stream<List<LunchItem>> watchItems(String householdId) =>
      _items(householdId)
          .orderBy('nameKey')
          .limit(LunchRepository.itemLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<LunchPlan>> watchPlans(
    String householdId, {
    required LunchWeek from,
    required LunchWeek to,
  }) =>
      _plans(householdId)
          .where('weekStart', isGreaterThanOrEqualTo: from.monday.iso)
          .where('weekStart', isLessThanOrEqualTo: to.monday.iso)
          .orderBy('weekStart', descending: true)
          .limit(LunchRepository.planLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<LunchPlan> watchPlan(
    String householdId, {
    required String childId,
    required LunchWeek week,
  }) => _plans(householdId)
      .doc(LunchPlan.idFor(childId, week))
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.data() ?? LunchPlan.empty(childId: childId, week: week),
      )
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<LunchFavourite>> watchFavourites(String householdId) =>
      _favourites(householdId)
          .limit(LunchRepository.favouriteLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<LunchPrep> watchPrep(String householdId, LunchWeek week) =>
      _household(householdId)
          .collection(prepPath)
          .doc(week.key)
          .withConverter<LunchPrep>(
            fromFirestore: (snapshot, _) =>
                LunchPrep.fromJson({...?snapshot.data(), 'id': snapshot.id}),
            toFirestore: (prep, _) => prep.toJson(),
          )
          .snapshots()
          .map((snapshot) => snapshot.data() ?? LunchPrep.empty(week.key))
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> seedItems(String householdId, List<LunchItem> items) =>
      _guarded(() {
        final batch = _firestore.batch();
        for (final item in items) {
          batch.set(_items(householdId).doc(item.id), item);
        }
        return batch.commit();
      });

  @override
  Future<String> addItem(String householdId, LunchItem item) async {
    try {
      // The library is deduplicated by name within a slot (lunch-box
      // ADR-0001): typing "apple slices" again picks the household's own.
      final existing = await _items(householdId)
          .where('nameKey', isEqualTo: item.nameKey)
          .limit(5)
          .get();
      final found = existing.docs
          .where((doc) => doc.data().slotName == item.slotName)
          .firstOrNull;
      if (found != null) return found.id;
      final document = _items(householdId).doc();
      await document.set(item.copyWith(id: document.id));
      return document.id;
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  @override
  Future<void> updateItem(String householdId, LunchItem item) => _guarded(
    () => _items(householdId).doc(item.id).update({
      'name': item.name,
      'nameKey': item.nameKey,
      'allergens': item.allergens,
      'prepAhead': item.prepAhead,
      'prepNote': item.prepNote,
    }),
  );

  @override
  Future<void> setItemArchived({
    required String householdId,
    required String itemId,
    required bool archived,
  }) => _guarded(
    () => _items(householdId).doc(itemId).update({'archived': archived}),
  );

  /// One write per school day the picks touch, all sent at once. The rules
  /// check every pick a write changes, and a write holding a whole week is
  /// past what Firestore evaluates in one request (lunch-box ADR-0010); a
  /// day is five slots, well inside it. Sent together, not one after
  /// another, so a week filled offline is queued whole.
  @override
  Future<void> setPicks({
    required String householdId,
    required String childId,
    required LunchWeek week,
    required Map<String, LunchPick?> picks,
  }) async {
    final byDay = <String, Map<String, Object?>>{};
    for (final MapEntry(:key, :value) in picks.entries) {
      final day = key.split('_').first;
      (byDay[day] ??= {})[key] = value?.toJson() ?? FieldValue.delete();
    }
    await Future.wait([
      for (final values in byDay.values)
        _writePlan(
          householdId: householdId,
          childId: childId,
          week: week,
          field: 'slots',
          values: values,
        ),
    ]);
  }

  @override
  Future<void> setFeedback({
    required String householdId,
    required String childId,
    required LunchWeek week,
    required int isoWeekday,
    required LunchFeedback? feedback,
  }) => _writePlan(
    householdId: householdId,
    childId: childId,
    week: week,
    field: 'feedback',
    values: {'$isoWeekday': feedback?.toJson() ?? FieldValue.delete()},
  );

  /// One write to one plan: the named keys of one map field, and the three
  /// fields that make a new plan a plan. Those three are the same on every
  /// write, so on an existing plan they change nothing.
  Future<void> _writePlan({
    required String householdId,
    required String childId,
    required LunchWeek week,
    required String field,
    required Map<String, Object?> values,
  }) => _guarded(
    () =>
        _household(householdId)
            .collection(plansPath)
            .doc(LunchPlan.idFor(childId, week))
            .set(
              {
                'childId': childId,
                'week': week.key,
                'weekStart': week.monday.iso,
                field: values,
              },
              SetOptions(
                mergeFields: [
                  FieldPath(const ['childId']),
                  FieldPath(const ['week']),
                  FieldPath(const ['weekStart']),
                  for (final key in values.keys) FieldPath([field, key]),
                ],
              ),
            ),
  );

  @override
  Future<String> addFavourite(
    String householdId,
    LunchFavourite favourite,
  ) async {
    try {
      final document = _favourites(householdId).doc();
      await document.set(favourite.copyWith(id: document.id));
      return document.id;
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  @override
  Future<void> deleteFavourite({
    required String householdId,
    required String favouriteId,
  }) => _guarded(() => _favourites(householdId).doc(favouriteId).delete());

  @override
  Future<void> setPrepDone({
    required String householdId,
    required LunchWeek week,
    required String itemId,
    required bool done,
  }) => _guarded(
    () => _household(householdId).collection(prepPath).doc(week.key).set({
      'done': done
          ? FieldValue.arrayUnion([itemId])
          : FieldValue.arrayRemove([itemId]),
    }, SetOptions(merge: true)),
  );

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
