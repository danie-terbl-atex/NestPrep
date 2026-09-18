import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/grocery_repository.dart';
import '../model/grocery_item.dart';
import '../model/grocery_list_view.dart';
import '../model/grocery_suggestion.dart';

/// The grocery list screen's controller. Two live reads — what is still to buy,
/// and what the household has bought recently — become one `AsyncState` so the
/// screen has one loading state, not two (foundation ADR-0006).
final class GroceryListController extends ChangeNotifier
    with ActionFailureHolder {
  GroceryListController({
    required GroceryRepository groceryRepository,
    required this.householdId,
    required this.memberId,
    DateTime Function()? now,
  }) : _repository = groceryRepository,
       _now = now ?? DateTime.now {
    _subscribe();
  }

  final GroceryRepository _repository;
  final String householdId;

  /// The profile acting: whoever ticks something is recorded as this member.
  final String memberId;
  final DateTime Function() _now;

  StreamSubscription<List<GroceryItem>>? _subscription;

  AsyncState<GroceryListView> _list = const AsyncLoading();

  AsyncState<GroceryListView> get list => _list;

  Future<void> retry() async {
    await _cancel();
    _list = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  Future<void> add(String name, {String? quantity}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await runAction(
      () => _repository.add(
        householdId: householdId,
        name: trimmed,
        quantity: quantity == null || quantity.trim().isEmpty
            ? null
            : quantity.trim(),
        addedBy: memberId,
      ),
    );
  }

  Future<void> toggleBought(GroceryItem item) => runAction(
    () => _repository.setBought(
      householdId: householdId,
      itemId: item.id,
      isBought: !item.isBought,
      memberId: memberId,
    ),
  );

  Future<void> rename(
    GroceryItem item, {
    required String name,
    String? quantity,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Future.value();
    return runAction(
      () => _repository.rename(
        householdId: householdId,
        itemId: item.id,
        name: trimmed,
        quantity: quantity == null || quantity.trim().isEmpty
            ? null
            : quantity.trim(),
      ),
    );
  }

  Future<void> remove(GroceryItem item) => runAction(
    () => _repository.remove(householdId: householdId, itemId: item.id),
  );

  Future<void> addFromSuggestion(GrocerySuggestion suggestion) =>
      add(suggestion.name);

  void _subscribe() {
    _subscription = _repository.watchItems(householdId).listen((items) {
      _list = AsyncData(GroceryListView.from(items: items, now: _now()));
      notifyListeners();
    }, onError: _onError);
  }

  void _onError(Object error) {
    _list = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  Future<void> _cancel() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
