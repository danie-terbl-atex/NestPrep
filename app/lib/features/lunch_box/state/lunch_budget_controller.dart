import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../data/lunch_budget_repository.dart';
import '../model/lunch_board.dart';
import '../model/lunch_budget.dart';
import '../model/lunch_budget_week.dart';
import '../model/lunch_price.dart';

/// Budget mode (lunch-box ADR-0007): the prices and the weekly budget — two
/// reads of its own — joined with the board the lunch controller already
/// publishes into one `LunchBudgetWeek`.
///
/// Every write needs premium, and the rules are what refuse it; a refusal is
/// held as `PremiumRequiredFailure` on budget mode so the screen can offer
/// premium rather than apologise.
final class LunchBudgetController extends ChangeNotifier
    with ActionFailureHolder {
  LunchBudgetController({
    required LunchBudgetRepository budgetRepository,
    required this.householdId,
    required this.memberId,
  }) : _repository = budgetRepository {
    _listen();
  }

  final LunchBudgetRepository _repository;
  final String householdId;
  final String memberId;

  final _subscriptions = <StreamSubscription<Object?>>[];
  List<LunchPrice>? _prices;
  LunchBudget? _budget;
  bool _hasBudget = false;
  AsyncState<LunchBoard> _board = const AsyncLoading();
  AppFailure? _readFailure;
  AsyncState<LunchBudgetWeek> _week = const AsyncLoading();

  AsyncState<LunchBudgetWeek> get week => _week;

  void followBoard(AsyncState<LunchBoard> board) {
    if (identical(board, _board)) return;
    _board = board;
    _publish();
  }

  /// [cents] for something that makes [portions] boxes.
  Future<void> setPrice({
    required String itemId,
    required int cents,
    required int portions,
  }) {
    if (cents < 0 ||
        cents > LunchPrice.centsLimit ||
        portions < 1 ||
        portions > LunchPrice.portionLimit) {
      recordFailure(
        const LunchPlanningFailure(LunchPlanningProblem.amountOutOfRange),
      );
      return Future.value();
    }
    return _premiumWrite(
      () => _repository.setPrice(
        householdId,
        LunchPrice(
          id: itemId,
          cents: cents,
          portions: portions,
          updatedBy: memberId,
        ),
      ),
    );
  }

  Future<void> clearPrice(String itemId) => runAction(
    () => _repository.clearPrice(householdId: householdId, itemId: itemId),
  );

  Future<void> setBudget(int cents) {
    if (cents < LunchBudget.minimumCents || cents > LunchBudget.centsLimit) {
      recordFailure(
        const LunchPlanningFailure(LunchPlanningProblem.amountOutOfRange),
      );
      return Future.value();
    }
    return _premiumWrite(
      () => _repository.setBudget(
        householdId,
        LunchBudget(id: LunchBudget.weekly, cents: cents, updatedBy: memberId),
      ),
    );
  }

  Future<void> clearBudget() =>
      runAction(() => _repository.clearBudget(householdId));

  Future<void> retry() async {
    await _cancel();
    _prices = null;
    _budget = null;
    _hasBudget = false;
    _readFailure = null;
    _week = const AsyncLoading();
    notifyListeners();
    _listen();
  }

  Future<void> _premiumWrite(Future<void> Function() write) =>
      runAction(() async {
        try {
          await write();
        } on PermissionDeniedFailure {
          throw const PremiumRequiredFailure(PremiumFeature.budgetMode);
        }
      });

  void _listen() {
    _subscriptions
      ..add(
        _repository.watchPrices(householdId).listen((prices) {
          _prices = prices;
          _publish();
        }, onError: _onError),
      )
      ..add(
        _repository.watchBudget(householdId).listen((budget) {
          _budget = budget;
          _hasBudget = true;
          _publish();
        }, onError: _onError),
      );
  }

  void _publish() {
    final failure = _readFailure;
    final board = _board;
    final prices = _prices;
    if (failure != null) {
      _week = AsyncFailure(failure);
    } else if (board is AsyncFailure<LunchBoard>) {
      _week = AsyncFailure(board.failure);
    } else if (board is AsyncData<LunchBoard> && prices != null && _hasBudget) {
      _week = AsyncData(
        LunchBudgetWeek(
          board: board.value,
          prices: {for (final price in prices) price.itemId: price},
          budget: _budget,
        ),
      );
    }
    notifyListeners();
  }

  void _onError(Object error) {
    _readFailure = error is AppFailure ? error : UnknownFailure(error);
    _publish();
  }

  Future<void> _cancel() async {
    final subscriptions = [..._subscriptions];
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
