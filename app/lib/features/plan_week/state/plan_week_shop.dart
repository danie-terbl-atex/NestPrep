import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/money/money.dart';
import '../../add_to_checkers/model/checkers_product.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../data/lunch_week_builder.dart';
import '../data/shop_week_groceries.dart';
import '../model/idea_search.dart';
import '../model/packing_preference.dart';
import '../model/plan_fallback.dart';
import '../model/shop_week.dart';
import '../model/shop_week_assembly.dart';
import 'shop_week_saver.dart';

/// Steps 4 and 5 of *Plan my week* (lunch-box ADR-0012): the week built from
/// what the shop had — by the model, or on the phone when it cannot help —
/// the parent's swaps and pack sizes, then the write and the grocery list.
final class PlanWeekShop {
  PlanWeekShop({
    required this._builder,
    required this._saver,
    required this._groceries,
    required this.onChange,
  });

  final LunchWeekBuilder _builder;
  final ShopWeekSaver _saver;
  final ShopWeekGroceries _groceries;
  final void Function() onChange;

  AsyncState<ShopWeek> _state = const AsyncLoading();
  ShopWeekSaved? _saved;
  bool _isSaving = false;
  int? _groceriesAdded;
  bool _isAddingGroceries = false;
  AppFailure? _failure;
  var _generation = 0;

  AsyncState<ShopWeek> get state => _state;
  ShopWeekSaved? get saved => _saved;
  bool get isSaving => _isSaving;
  int? get groceriesAdded => _groceriesAdded;
  bool get isAddingGroceries => _isAddingGroceries;

  /// What went wrong saving or adding to the list, for a banner.
  AppFailure? get failure => _failure;

  ShopWeek? get _week => switch (_state) {
    AsyncData(:final value) => value,
    _ => null,
  };

  /// The week from [searches], read against [budget] — the household's, as
  /// this phone last heard it, when the server does not say.
  Future<void> build({
    required String householdId,
    required LunchWeek week,
    required LunchBoard board,
    required Set<String> childIds,
    required List<IdeaSearch> searches,
    required PackingChoice packing,
    required Money? budget,
  }) async {
    final generation = ++_generation;
    _state = const AsyncLoading();
    onChange();
    AsyncState<ShopWeek> next;
    try {
      final reply = await _builder.build(
        householdId: householdId,
        week: week,
        childIds: childIds,
        searches: searches,
        packing: packing,
      );
      next = AsyncData(
        ShopWeekAssembly.fromReply(
          board: board,
          childIds: childIds,
          searches: searches,
          reply: reply,
          slots: packing.slots,
          budget: switch (reply.budgetCents) {
            final cents? => Money(cents),
            null => budget,
          },
        ),
      );
    } on AppFailure catch (failure) {
      final reason = PlanFallbackReason.of(failure);
      next = reason == null
          ? AsyncFailure(failure)
          : AsyncData(
              ShopWeekAssembly.fallback(
                board: board,
                childIds: childIds,
                searches: searches,
                budget: budget,
                slots: packing.slots,
                reason: reason,
              ),
            );
    }
    if (generation != _generation) return;
    _state = next;
    onChange();
  }

  void swap(String childId, String slotKey, ShopPick? pick) =>
      _edit((week) => week.withPick(childId, slotKey, pick));

  /// Writes the week; true when it went in.
  Future<bool> use(LunchBoard board) async {
    final plan = _week;
    if (plan == null || _isSaving) return false;
    _isSaving = true;
    _failure = null;
    onChange();
    try {
      _saved = await _saver.save(plan, board: board);
    } on AppFailure catch (failure) {
      _failure = failure;
    }
    _isSaving = false;
    onChange();
    return _saved != null;
  }

  /// The basket onto the grocery list, matched to its products; [quantityOf]
  /// says a number of packs in words.
  Future<void> addToGroceries(String Function(int packs) quantityOf) async {
    final plan = _week;
    if (plan == null || _isAddingGroceries) return;
    _isAddingGroceries = true;
    _failure = null;
    onChange();
    try {
      _groceriesAdded = await _groceries.add([
        for (final line in plan.basket.lines)
          if (_productOf(plan, line.key) case final product?)
            (product: product, quantity: quantityOf(line.packs)),
      ]);
    } on AppFailure catch (failure) {
      _failure = failure;
    }
    _isAddingGroceries = false;
    onChange();
  }

  void dismissFailure() {
    _failure = null;
    onChange();
  }

  /// Forgets the week; an answer still on its way is dropped.
  void clear() {
    _generation++;
    _state = const AsyncLoading();
    _saved = null;
    _groceriesAdded = null;
    _failure = null;
  }

  void _edit(ShopWeek Function(ShopWeek) edit) {
    final plan = _week;
    if (plan == null || _saved != null) return;
    _state = AsyncData(edit(plan));
    onChange();
  }

  static CheckersProduct? _productOf(ShopWeek plan, String productId) {
    for (final search in plan.searches) {
      if (search.keptProduct(productId) case final kept?) return kept.product;
    }
    return null;
  }
}
