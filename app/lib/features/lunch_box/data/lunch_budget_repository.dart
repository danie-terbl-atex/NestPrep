import '../model/lunch_budget.dart';
import '../model/lunch_price.dart';

/// Budget mode as Firestore holds it (lunch-box ADR-0007): a price per
/// library item and the household's weekly budget. Every write needs premium
/// — without it the rules refuse, and the refusal arrives as
/// `PermissionDeniedFailure`. Reading never needs it.
abstract interface class LunchBudgetRepository {
  /// As many prices as the library can hold items.
  static const priceLimit = 400;

  Stream<List<LunchPrice>> watchPrices(String householdId);

  /// The weekly budget, or null when none is set.
  Stream<LunchBudget?> watchBudget(String householdId);

  Future<void> setPrice(String householdId, LunchPrice price);

  Future<void> clearPrice({
    required String householdId,
    required String itemId,
  });

  Future<void> setBudget(String householdId, LunchBudget budget);

  Future<void> clearBudget(String householdId);
}
