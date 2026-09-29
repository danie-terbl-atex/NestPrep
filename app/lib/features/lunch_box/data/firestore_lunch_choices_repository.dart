import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/lunch_choices.dart';
import '../model/lunch_pick.dart';
import '../model/lunch_plan.dart';
import '../model/lunch_slot.dart';
import '../model/lunch_week.dart';
import 'firestore_lunch_repository.dart';
import 'lunch_choices_repository.dart';

final class FirestoreLunchChoicesRepository implements LunchChoicesRepository {
  FirestoreLunchChoicesRepository(this._firestore);

  static const choicesPath = 'lunchChoices';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _household(String householdId) =>
      _firestore
          .collection(FirestoreLunchRepository.householdsPath)
          .doc(householdId);

  CollectionReference<LunchChoices> _choices(String householdId) =>
      typedCollection(
        _household(householdId).collection(choicesPath),
        fromJson: LunchChoices.fromJson,
        toJson: (choices) => choices.toJson(),
      );

  @override
  Stream<List<LunchChoices>> watchWeek(String householdId, LunchWeek week) =>
      _choices(householdId)
          .where('week', isEqualTo: week.key)
          .limit(LunchChoicesRepository.choicesLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<LunchChoices> watchChoices(
    String householdId, {
    required String childId,
    required LunchWeek week,
  }) => _choices(householdId)
      .doc(LunchPlan.idFor(childId, week))
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.data() ?? LunchChoices.none(childId: childId, week: week),
      )
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> setOptions({
    required String householdId,
    required String childId,
    required LunchWeek week,
    required int isoWeekday,
    required Map<String, List<LunchPick>?> options,
    required String by,
  }) => _guarded(
    () => _household(householdId)
        .collection(choicesPath)
        .doc(LunchPlan.idFor(childId, week))
        .set(
          {
            'childId': childId,
            'week': week.key,
            'editedDay': '$isoWeekday',
            'updatedBy': by,
            'updatedAt': FieldValue.serverTimestamp(),
            'options': {
              for (final MapEntry(:key, :value) in options.entries)
                key: value == null
                    ? FieldValue.delete()
                    : [for (final pick in value) pick.toJson()],
            },
            // A choice made among options that have changed is not a choice
            // any more.
            'chosen': {
              for (final key in options.keys) key: FieldValue.delete(),
            },
          },
          SetOptions(
            mergeFields: [
              FieldPath(const ['childId']),
              FieldPath(const ['week']),
              FieldPath(const ['editedDay']),
              FieldPath(const ['updatedBy']),
              FieldPath(const ['updatedAt']),
              for (final key in options.keys) ...[
                FieldPath(['options', key]),
                FieldPath(['chosen', key]),
              ],
            ],
          ),
        ),
  );

  @override
  Future<void> choose({
    required String householdId,
    required String childId,
    required LunchWeek week,
    required int isoWeekday,
    required LunchSlot slot,
    required LunchPick pick,
  }) => _guarded(() {
    final id = LunchPlan.idFor(childId, week);
    final key = LunchPlan.slotKey(isoWeekday, slot);
    final household = _household(householdId);
    final batch = _firestore.batch()
      ..set(
        household.collection(FirestoreLunchRepository.plansPath).doc(id),
        {
          'childId': childId,
          'week': week.key,
          'weekStart': week.monday.iso,
          'slots': {key: pick.toJson()},
        },
        SetOptions(
          mergeFields: [
            FieldPath(const ['childId']),
            FieldPath(const ['week']),
            FieldPath(const ['weekStart']),
            FieldPath(['slots', key]),
          ],
        ),
      )
      ..update(household.collection(choicesPath).doc(id), {
        FieldPath(['chosen', key]): pick.itemId,
        FieldPath(const ['chosenKey']): key,
      });
    return batch.commit();
  });

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
