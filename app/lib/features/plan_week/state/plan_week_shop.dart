import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/money/money.dart';
import '../../groceries/model/product_match.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_budget_week.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/model/lunch_variety.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../data/lunch_week_builder.dart';
import '../data/shop_week_groceries.dart';
import '../model/idea_search.dart';
import '../model/packing_preference.dart';
import '../model/plan_fallback.dart';
import '../model/shop_list_entry.dart';
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
  List<ShopListEntry>? _listed;
  bool _isAddingGroceries = false;
  AppFailure? _failure;
  var _generation = 0;

  AsyncState<ShopWeek> get state => _state;
  ShopWeekSaved? get saved => _saved;
  bool get isSaving => _isSaving;

  /// How many products the basket added to the list — null until it has.
  int? get groceriesAdded => _listed?.where((entry) => entry.isNew).length;

  /// The basket as it stands on the grocery list, once it is there — what a
  /// cart push names (lunch-box ADR-0026 §6).
  List<ShopListEntry>? get listed => _listed;
  bool get isAddingGroceries => _isAddingGroceries;

  /// What went wrong saving or adding to the list, for a banner.
  AppFailure? get failure => _failure;

  /// The week was built by the model, not on the phone — so the done step
  /// may say the AI did it (design-system ADR-0012). False for a week the
  /// phone built because the AI could not help.
  bool get isFromAi => _week?.source == PlanSource.ai;

  ShopWeek? get _week => switch (_state) {
    AsyncData(:final value) => value,
    _ => null,
  };

  /// The week from [searches], read against the household's whole week:
  /// [budgetWeek] is budget mode's picture of it as this phone last heard —
  /// what is packed already, the prices, and the budget when the server does
  /// not say.
  Future<void> build({
    required String householdId,
    required LunchWeek week,
    required LunchBoard board,
    required Set<String> childIds,
    required List<IdeaSearch> searches,
    required PackingChoice packing,
    required LunchVariety variety,
    required LunchBudgetWeek? budgetWeek,
  }) async {
    final budget = budgetWeek?.budget?.money;
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
        variety: variety,
      );
      next = AsyncData(
        ShopWeekAssembly.fromReply(
          board: board,
          childIds: childIds,
          searches: searches,
          reply: reply,
          packing: packing,
          budget: switch (reply.budgetCents) {
            final cents? => Money(cents),
            null => budget,
          },
          weekSoFar: budgetWeek,
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
                packing: packing,
                variety: variety,
                reason: reason,
                weekSoFar: budgetWeek,
              ),
            );
    }
    if (generation != _generation) return;
    _state = next;
    onChange();
  }

  void swap(String childId, String slotKey, ShopPick? pick) =>
      _edit((week) => week.withPick(childId, slotKey, pick));

  /// [pick] on every day [childId]'s [slot] is planned, and for the
  /// children sharing it (lunch-box ADR-0028 §6).
  void swapEveryDay(String childId, int day, LunchSlot slot, ShopPick? pick) =>
      _edit((week) => week.withPickEveryDay(childId, day, slot, pick));

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
  /// says a number of packs in words. Answers the basket as it stands on the
  /// list — at once when it is there already — or null when it is not.
  Future<List<ShopListEntry>?> addToGroceries(
    String Function(int packs) quantityOf,
  ) async {
    final plan = _week;
    if (_listed case final listed?) return listed;
    if (plan == null || _isAddingGroceries) return null;
    _isAddingGroceries = true;
    _failure = null;
    onChange();
    try {
      _listed = await _groceries.add([
        for (final line in plan.basket.lines)
          if (plan.basketProduct(line.key) case final checked?)
            (
              product: checked.product,
              name: plan.shoppingName(line.key),
              quantity: quantityOf(line.packs),
              packs: line.packs,
            ),
      ]);
    } on AppFailure catch (failure) {
      _failure = failure;
    }
    _isAddingGroceries = false;
    onChange();
    return _listed;
  }

  /// What is waiting on the list at [shop], to push again (lunch-box
  /// ADR-0027); [packsOf] reads packs back from quantity words.
  Future<List<ShopListEntry>> waitingOnList(
    ProductRetailer shop,
    int Function(String? quantity) packsOf,
  ) => _groceries.waitingAt(shop, packsOf);

  void dismissFailure() {
    _failure = null;
    onChange();
  }

  /// Forgets the week; an answer still on its way is dropped.
  void clear() {
    _generation++;
    _state = const AsyncLoading();
    _saved = null;
    _listed = null;
    _failure = null;
  }

  void _edit(ShopWeek Function(ShopWeek) edit) {
    final plan = _week;
    if (plan == null || _saved != null) return;
    _state = AsyncData(edit(plan));
    onChange();
  }
}
