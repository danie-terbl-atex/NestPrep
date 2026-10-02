import 'grocery_item.dart';
import 'grocery_suggestion.dart';

/// What the grocery screen renders: the list as a person reads it, and the
/// chips above the input. Derived once per emission rather than in the build
/// method (`FE-12`).
///
/// The split happens here, off one snapshot, rather than in two Firestore
/// queries — two queries over the same collection disagree while a write is
/// pending, and the item shows twice or not at all (groceries phase 1).
class GroceryListView {
  const GroceryListView({
    required this.toBuy,
    required this.justBought,
    required this.suggestions,
  });

  factory GroceryListView.from({
    required List<GroceryItem> items,
    required DateTime now,
  }) {
    final toBuy = <GroceryItem>[];
    final bought = <GroceryItem>[];
    for (final item in items) {
      (item.isBought ? bought : toBuy).add(item);
    }

    // Newest purchase first, and a tick the server has not timed yet counts as
    // just now — which it is.
    bought.sort((a, b) => (b.boughtAt ?? now).compareTo(a.boughtAt ?? now));

    return GroceryListView(
      toBuy: toBuy,
      justBought: [
        for (final item in bought)
          if (item.isStillVisible(now)) item,
      ],
      suggestions: rankSuggestions(bought),
    );
  }

  /// Still to buy, newest first.
  final List<GroceryItem> toBuy;

  /// Bought within the last day, newest first — shown struck through so a wrong
  /// tick can be undone (groceries ADR-0001).
  final List<GroceryItem> justBought;

  final List<GrocerySuggestion> suggestions;

  bool get isEmpty => toBuy.isEmpty && justBought.isEmpty;

  /// Still to buy, with a shop's product picked — what *Add to Checkers*
  /// would send.
  List<GroceryItem> get matchedToBuy => [
    for (final item in toBuy)
      if (item.productMatch != null) item,
  ];
}
