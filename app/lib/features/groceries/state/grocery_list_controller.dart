import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/grocery_repository.dart';
import '../model/grocery_item.dart';
import '../model/grocery_list_view.dart';
import '../model/grocery_suggestion.dart';

/// The grocery list screen's controller. Two live reads — what is still to buy,
/// and what the household has bought recently — become one `AsyncState` so the
/// screen has one loading state, not two (foundation ADR-0006).
final class GroceryListController extends ChangeNotifier {
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

  StreamSubscription<List<GroceryItem>>? _unboughtSubscription;
  StreamSubscription<List<GroceryItem>>? _boughtSubscription;

  List<GroceryItem>? _unbought;
  List<GroceryItem>? _recentlyBought;

  AsyncState<GroceryListView> _list = const AsyncLoading();
  AppFailure? _actionFailure;

  AsyncState<GroceryListView> get list => _list;
  AppFailure? get actionFailure => _actionFailure;

  void dismissActionFailure() {
    if (_actionFailure == null) return;
    _actionFailure = null;
    notifyListeners();
  }

  Future<void> retry() async {
    await _cancel();
    _unbought = null;
    _recentlyBought = null;
    _list = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  Future<void> add(String name, {String? quantity}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _run(
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

  Future<void> toggleBought(GroceryItem item) => _run(
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
    return _run(
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

  Future<void> remove(GroceryItem item) =>
      _run(() => _repository.remove(householdId: householdId, itemId: item.id));

  Future<void> addFromSuggestion(GrocerySuggestion suggestion) =>
      add(suggestion.name);

  Future<void> _run(Future<void> Function() action) async {
    _actionFailure = null;
    try {
      await action();
    } on AppFailure catch (failure) {
      _actionFailure = failure;
      notifyListeners();
    }
  }

  void _subscribe() {
    _unboughtSubscription = _repository.watchUnbought(householdId).listen((
      items,
    ) {
      _unbought = items;
      _publish();
    }, onError: _onError);
    _boughtSubscription = _repository.watchRecentlyBought(householdId).listen((
      items,
    ) {
      _recentlyBought = items;
      _publish();
    }, onError: _onError);
  }

  void _publish() {
    final unbought = _unbought;
    final bought = _recentlyBought;
    if (unbought == null || bought == null) return;
    _list = AsyncData(
      GroceryListView.from(
        unbought: unbought,
        recentlyBought: bought,
        now: _now(),
      ),
    );
    notifyListeners();
  }

  void _onError(Object error) {
    _list = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  Future<void> _cancel() async {
    await _unboughtSubscription?.cancel();
    await _boughtSubscription?.cancel();
    _unboughtSubscription = null;
    _boughtSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
