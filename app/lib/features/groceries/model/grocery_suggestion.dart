import 'grocery_item.dart';
import 'item_name.dart';

/// A name the household buys often enough to be one tap away.
class GrocerySuggestion {
  const GrocerySuggestion({required this.name, required this.timesBought});

  /// The spelling to show: the most recent one the household used, so a name
  /// they have since corrected does not come back wrong.
  final String name;
  final int timesBought;
}

/// Ranks the household's own buying history into the chips above the input:
/// most bought first, and the most recent of equally-bought names first, so a
/// week's shopping does not reorder under somebody's hand (groceries ADR-0001).
///
/// [boughtItems] is expected newest-first, which is how the repository reads it.
List<GrocerySuggestion> rankSuggestions(
  List<GroceryItem> boughtItems, {
  int limit = 8,
}) {
  final counts = <String, int>{};
  final mostRecentSpelling = <String, String>{};
  final firstSeenAt = <String, int>{};

  for (var index = 0; index < boughtItems.length; index++) {
    final item = boughtItems[index];
    final key = normalisedItemName(item.name);
    if (key.isEmpty) continue;
    counts[key] = (counts[key] ?? 0) + 1;
    mostRecentSpelling.putIfAbsent(key, () => item.name.trim());
    firstSeenAt.putIfAbsent(key, () => index);
  }

  final keys = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      if (byCount != 0) return byCount;
      return firstSeenAt[a]!.compareTo(firstSeenAt[b]!);
    });

  return [
    for (final key in keys.take(limit))
      GrocerySuggestion(
        name: mostRecentSpelling[key]!,
        timesBought: counts[key]!,
      ),
  ];
}
