import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/lunch_budget.dart';
import '../model/lunch_price.dart';
import 'lunch_budget_repository.dart';

final class FirestoreLunchBudgetRepository implements LunchBudgetRepository {
  FirestoreLunchBudgetRepository(this._firestore);

  static const householdsPath = 'households';
  static const pricesPath = 'lunchPrices';
  static const budgetPath = 'lunchBudget';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _household(String householdId) =>
      _firestore.collection(householdsPath).doc(householdId);

  CollectionReference<LunchPrice> _prices(String householdId) =>
      typedCollection(
        _household(householdId).collection(pricesPath),
        fromJson: LunchPrice.fromJson,
        toJson: (price) => price.toJson(),
      );

  CollectionReference<LunchBudget> _budgets(String householdId) =>
      typedCollection(
        _household(householdId).collection(budgetPath),
        fromJson: LunchBudget.fromJson,
        toJson: (budget) => budget.toJson(),
      );

  @override
  Stream<List<LunchPrice>> watchPrices(String householdId) =>
      _prices(householdId)
          .limit(LunchBudgetRepository.priceLimit)
          .snapshots()
          .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<LunchBudget?> watchBudget(String householdId) => _budgets(householdId)
      .doc(LunchBudget.weekly)
      .snapshots()
      .map((snapshot) => snapshot.data())
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> setPrice(String householdId, LunchPrice price) => _guarded(
    () => _prices(
      householdId,
    ).doc(price.itemId).set(price.copyWith(updatedAt: null)),
  );

  @override
  Future<void> clearPrice({
    required String householdId,
    required String itemId,
  }) => _guarded(() => _prices(householdId).doc(itemId).delete());

  @override
  Future<void> setBudget(String householdId, LunchBudget budget) => _guarded(
    () => _budgets(
      householdId,
    ).doc(LunchBudget.weekly).set(budget.copyWith(updatedAt: null)),
  );

  @override
  Future<void> clearBudget(String householdId) =>
      _guarded(() => _budgets(householdId).doc(LunchBudget.weekly).delete());

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
