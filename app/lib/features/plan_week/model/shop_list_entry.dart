import 'package:flutter/foundation.dart';

/// One basket line as it stands on the grocery list after *Plan my week*
/// put it there (lunch-box ADR-0012 §1.5, ADR-0026 §6): the item it is, what
/// it is called, how many packs the week wants, and whether this run added
/// it or it was on the list already.
@immutable
final class ShopListEntry {
  const ShopListEntry({
    required this.itemId,
    required this.name,
    required this.packs,
    required this.isNew,
  });

  final String itemId;
  final String name;
  final int packs;
  final bool isNew;

  /// The most packs of one item a cart push may ask for — the server's own
  /// bound (add-to-pnp ADR-0004 §1).
  static const maxPacks = 24;

  /// How many packs each item needs across [entries]: two basket lines that
  /// landed on one item (the same name) add up, never replace each other;
  /// at least one and at most [maxPacks].
  static Map<String, int> packsByItem(List<ShopListEntry> entries) {
    final packs = <String, int>{};
    for (final entry in entries) {
      packs[entry.itemId] = (packs[entry.itemId] ?? 0) + entry.packs;
    }
    return {
      for (final MapEntry(key: itemId, value: count) in packs.entries)
        itemId: count.clamp(1, maxPacks),
    };
  }
}
