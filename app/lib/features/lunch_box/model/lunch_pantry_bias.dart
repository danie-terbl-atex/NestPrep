import 'lunch_favourite.dart';
import 'lunch_fill_bias.dart';
import 'lunch_suggestions.dart';

/// Planning from what is in the house (lunch-box ADR-0006): among a slot's
/// suggestions, what the pantry still has comes first, and a go-to box is
/// packed only when the pantry has everything in it.
///
/// It reorders `suggested` only — the disliked and the unsafe stay where
/// ADR-0003 and ADR-0001 put them — and within each half the ranking is
/// untouched, so the best-eaten thing in the pantry still leads.
final class LunchPantryBias implements LunchFillBias {
  LunchPantryBias(Map<String, int> available)
    : _available = Map.unmodifiable(available);

  /// Item id → what the pantry has left before this fill takes anything.
  final Map<String, int> _available;

  /// Whether the pantry still has one of [itemId] once [added] is taken.
  bool hasLeft(String itemId, [Map<String, int> added = const {}]) =>
      (_available[itemId] ?? 0) - (added[itemId] ?? 0) > 0;

  int availableOf(String itemId) => _available[itemId] ?? 0;

  @override
  bool acceptsFavourite(LunchFavourite favourite, Map<String, int> added) {
    final needs = <String, int>{};
    for (final (_, pick) in favourite.box.filled) {
      needs[pick.itemId] = (needs[pick.itemId] ?? 0) + 1;
    }
    return needs.entries.every(
      (need) =>
          (_available[need.key] ?? 0) - (added[need.key] ?? 0) >= need.value,
    );
  }

  @override
  LunchSuggestion? choose(RankedLunchItems ranked, Map<String, int> added) =>
      ranked.suggested
          .where((entry) => hasLeft(entry.item.id, added))
          .firstOrNull ??
      ranked.best;

  /// [ranked] with what the pantry has leading its suggestions.
  RankedLunchItems order(RankedLunchItems ranked) => RankedLunchItems(
    suggested: [
      ...ranked.suggested.where((entry) => hasLeft(entry.item.id)),
      ...ranked.suggested.where((entry) => !hasLeft(entry.item.id)),
    ],
    disliked: ranked.disliked,
    unsafe: ranked.unsafe,
  );
}
