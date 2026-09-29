import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import 'lunch_item.dart';
import 'lunch_packed_day.dart';
import 'lunch_pantry_entry.dart';
import 'lunch_plan.dart';
import 'lunch_week.dart';

/// One pantry entry beside what the week still needs of it.
@immutable
class LunchPantryLine {
  const LunchPantryLine({
    required this.item,
    required this.entry,
    required this.stillToPack,
  });

  final LunchItem item;
  final LunchPantryEntry entry;

  /// Boxes from today on, for every child, that still hold it.
  final int stillToPack;

  int get portions => entry.portions;

  /// What is left once the week's boxes have had theirs — below zero when
  /// the week needs more than the house has.
  int get available => portions - stillToPack;

  bool get isShort => available < 0;
}

/// Something the week's boxes need that the pantry does not cover.
@immutable
class LunchShortfall {
  const LunchShortfall({required this.item, required this.boxes});

  final LunchItem item;

  /// How many boxes' worth to buy.
  final int boxes;
}

/// The household's pantry held against one school week (lunch-box
/// ADR-0006): what is in the house, what the week's boxes still need of it,
/// and so what is left over and what is missing. Derived on every emission,
/// never stored.
///
/// A box is still to pack when its day is later than today, or is today and
/// nobody has marked it packed. A packed box has already taken its portions
/// out of the pantry, so counting it again would take them twice.
@immutable
class LunchPantryWeek {
  LunchPantryWeek._({
    required List<LunchPantryLine> lines,
    required List<LunchShortfall> shortfall,
    required Map<String, int> stock,
    required Map<String, int> stillToPack,
    required Set<String> packedIds,
  }) : lines = List.unmodifiable(lines),
       shortfall = List.unmodifiable(shortfall),
       _stock = Map.unmodifiable(stock),
       _stillToPack = Map.unmodifiable(stillToPack),
       _packedIds = Set.unmodifiable(packedIds);

  factory LunchPantryWeek.from({
    required LunchWeek week,
    required CalendarDate today,
    required List<LunchPantryEntry> entries,
    required Iterable<LunchPlan> plans,
    required List<LunchPackedDay> packed,
    required Map<String, LunchItem> library,
  }) {
    final packedIds = {for (final day in packed) day.id};
    final stillToPack = <String, int>{};
    for (final plan in plans.where((plan) => plan.week == week.key)) {
      for (final date in week.schoolDays) {
        if (date.isBefore(today)) continue;
        final packedId = LunchPackedDay.idFor(plan.childId, date);
        if (date == today && packedIds.contains(packedId)) continue;
        for (final (_, pick) in plan.boxOn(date.weekday).filled) {
          stillToPack[pick.itemId] = (stillToPack[pick.itemId] ?? 0) + 1;
        }
      }
    }
    final stock = {for (final entry in entries) entry.itemId: entry.portions};
    final lines = [
      for (final entry in entries)
        if (library[entry.itemId] case final item?)
          LunchPantryLine(
            item: item,
            entry: entry,
            stillToPack: stillToPack[entry.itemId] ?? 0,
          ),
    ]..sort((a, b) => a.item.nameKey.compareTo(b.item.nameKey));
    final shortfall = [
      for (final MapEntry(key: itemId, value: needed) in stillToPack.entries)
        if (library[itemId] case final item? when needed > (stock[itemId] ?? 0))
          LunchShortfall(item: item, boxes: needed - (stock[itemId] ?? 0)),
    ]..sort((a, b) => a.item.nameKey.compareTo(b.item.nameKey));
    return LunchPantryWeek._(
      lines: lines,
      shortfall: shortfall,
      stock: stock,
      stillToPack: stillToPack,
      packedIds: packedIds,
    );
  }

  /// Every entry the library still knows, by name.
  final List<LunchPantryLine> lines;

  /// What to buy for the rest of the week, by name.
  final List<LunchShortfall> shortfall;

  final Map<String, int> _stock;
  final Map<String, int> _stillToPack;
  final Set<String> _packedIds;

  bool get isEmpty => lines.isEmpty;

  bool has(String itemId) => _stock.containsKey(itemId);

  int stockOf(String itemId) => _stock[itemId] ?? 0;

  /// In the house, less what the week's boxes still need; below zero is
  /// short.
  int availableOf(String itemId) =>
      stockOf(itemId) - (_stillToPack[itemId] ?? 0);

  /// Every item's availability, for a fill to spend (`LunchPantryBias`).
  Map<String, int> get availability => {
    for (final itemId in {..._stock.keys, ..._stillToPack.keys})
      itemId: availableOf(itemId),
  };

  bool isPacked(String childId, CalendarDate date) =>
      _packedIds.contains(LunchPackedDay.idFor(childId, date));

  /// Every portion the shortfall asks for, across items.
  int get boxesShort =>
      shortfall.fold(0, (total, missing) => total + missing.boxes);
}
