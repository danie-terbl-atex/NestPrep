import '../../../shared/money/money.dart';
import 'lunch_board.dart';
import 'lunch_budget.dart';
import 'lunch_budget_reading.dart';
import 'lunch_cheaper_swaps.dart';
import 'lunch_item.dart';
import 'lunch_price.dart';
import 'lunch_week_cost.dart';

/// Budget mode's whole picture of one school week (lunch-box ADR-0007): the
/// board's boxes in money, the budget they are read against, and the prices
/// behind both. Built once per emission of any read; a child's swaps are
/// worked out the first time somebody asks for them, then kept.
class LunchBudgetWeek {
  LunchBudgetWeek({
    required this.board,
    required Map<String, LunchPrice> prices,
    required this.budget,
  }) : prices = Map.unmodifiable(prices),
       cost = LunchWeekCost.of(board: board, prices: prices);

  final LunchBoard board;
  final Map<String, LunchPrice> prices;
  final LunchBudget? budget;
  final LunchWeekCost cost;

  final _swaps = <String, List<LunchCheaperSwap>>{};

  /// The week against the budget, or null when none is set.
  LunchBudgetReading? get reading => switch (budget) {
    null => null,
    final budget => LunchBudgetReading(
      spent: cost.total.money,
      budget: budget.money,
    ),
  };

  Money get spent => cost.total.money;

  LunchPrice? priceOf(String itemId) => prices[itemId];

  /// Every item still in the library, priced ones last, by name — what the
  /// price list shows.
  List<LunchItem> get pricingOrder =>
      [
        for (final item in board.library)
          if (!item.archived) item,
      ]..sort((a, b) {
        final aPriced = prices.containsKey(a.id) ? 1 : 0;
        final bPriced = prices.containsKey(b.id) ? 1 : 0;
        if (aPriced != bPriced) return aPriced - bPriced;
        return a.nameKey.compareTo(b.nameKey);
      });

  /// Cheaper swaps for one child's week, biggest saving first.
  List<LunchCheaperSwap> swapsFor(String childId) => _swaps.putIfAbsent(
    childId,
    () => switch (board.childWeek(childId)) {
      null => const [],
      final childWeek => LunchCheaperSwaps.find(
        board: board,
        childWeek: childWeek,
        prices: prices,
      ),
    },
  );
}
