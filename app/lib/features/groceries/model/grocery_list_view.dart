import 'grocery_item.dart';
import 'grocery_suggestion.dart';

/// What the grocery screen renders: the list as a person reads it, and the
/// chips above the input. Derived once per emission rather than in the build
/// method (`FE-12`).
class GroceryListView {
  const GroceryListView({
    required this.toBuy,
    required this.justBought,
    required this.suggestions,
  });

  factory GroceryListView.from({
    required List<GroceryItem> unbought,
    required List<GroceryItem> recentlyBought,
    required DateTime now,
  }) {
    final justBought = [
      for (final item in recentlyBought)
        if (item.isStillVisible(now)) item,
    ];
    return GroceryListView(
      toBuy: unbought,
      justBought: justBought,
      suggestions: rankSuggestions(recentlyBought),
    );
  }

  /// Still to buy, newest first.
  final List<GroceryItem> toBuy;

  /// Bought within the last day, newest first — shown struck through so a wrong
  /// tick can be undone (groceries ADR-0001).
  final List<GroceryItem> justBought;

  final List<GrocerySuggestion> suggestions;

  bool get isEmpty => toBuy.isEmpty && justBought.isEmpty;
}
