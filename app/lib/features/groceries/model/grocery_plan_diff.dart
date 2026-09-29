import 'package:flutter/foundation.dart';

import 'grocery_item.dart';
import 'grocery_plan_line.dart';

/// A proposal beside the item on the list it was matched to.
typedef MatchedLine = ({GroceryPlanLine line, GroceryItem item});

/// What the week's plans would change on the list, and why the rest is left
/// alone (groceries ADR-0002). Pure, so the rules that matter most — never
/// touch what a person typed, never touch what somebody ticked, never touch
/// another week — are pinned by tests on this class alone.
///
/// The review sheet shows every group; keep-in-step applies [toAdd],
/// [toRefresh] and [toRemove] whole.
@immutable
class GroceryPlanDiff {
  const GroceryPlanDiff._({
    required this.week,
    required this.toAdd,
    required this.toRefresh,
    required this.toRemove,
    required this.added,
    required this.onList,
    required this.recentlyBought,
    required this.staples,
  });

  /// Classifies [lines] for [week] (`YYYY-Www`) against the list's [items].
  factory GroceryPlanDiff.of({
    required String week,
    required List<GroceryPlanLine> lines,
    required List<GroceryItem> items,
    required Set<String> staples,
    required DateTime now,
  }) {
    final builder = _DiffBuilder(week: week, items: items, now: now);
    for (final line in lines) {
      builder.classify(line, isStaple: staples.contains(line.key));
    }
    final wanted = {
      for (final line in lines)
        if (!staples.contains(line.key)) line.key,
    };
    return GroceryPlanDiff._(
      week: week,
      toAdd: List.unmodifiable(builder.toAdd),
      toRefresh: List.unmodifiable(builder.toRefresh),
      toRemove: List.unmodifiable(builder.noLongerPlanned(wanted)),
      added: List.unmodifiable(builder.added),
      onList: List.unmodifiable(builder.onList),
      recentlyBought: List.unmodifiable(builder.recentlyBought),
      staples: List.unmodifiable(builder.staples),
    );
  }

  /// How far back a purchase still counts as *bought recently*.
  static const recentlyBoughtWithin = Duration(days: 3);

  final String week;

  /// Nothing on the list has this name: offered ticked.
  final List<GroceryPlanLine> toAdd;

  /// This week's item from the plans, unbought, whose amount or reasons moved.
  final List<MatchedLine> toRefresh;

  /// This week's items from the plans, unbought, that no plan asks for now.
  final List<GroceryItem> toRemove;

  /// This week's item from the plans, unbought and up to date.
  final List<MatchedLine> added;

  /// Already on the list — typed by a person, or left from another week.
  final List<MatchedLine> onList;

  /// Bought in the last few days, or this week's item was already bought:
  /// offered unticked.
  final List<MatchedLine> recentlyBought;

  /// Marked *usually in the house*; never proposed.
  final List<GroceryPlanLine> staples;

  /// Whether the plans would change anything at all.
  bool get hasChanges =>
      toAdd.isNotEmpty || toRefresh.isNotEmpty || toRemove.isNotEmpty;

  /// Whether the plans say anything this week.
  bool get isEmpty =>
      !hasChanges &&
      added.isEmpty &&
      onList.isEmpty &&
      recentlyBought.isEmpty &&
      staples.isEmpty;
}

/// Walks the lines once, holding the list's items indexed by name.
class _DiffBuilder {
  _DiffBuilder({required this.week, required this.items, required this.now});

  final String week;
  final List<GroceryItem> items;
  final DateTime now;

  final toAdd = <GroceryPlanLine>[];
  final toRefresh = <MatchedLine>[];
  final added = <MatchedLine>[];
  final onList = <MatchedLine>[];
  final recentlyBought = <MatchedLine>[];
  final staples = <GroceryPlanLine>[];

  bool _isThisWeeks(GroceryItem item) =>
      item.isFromPlans && item.sourceWeek == week;

  void classify(GroceryPlanLine line, {required bool isStaple}) {
    if (isStaple) {
      staples.add(line);
      return;
    }
    final matches = [
      for (final item in items)
        if (item.matchKey == line.key) item,
    ];
    final unbought = matches.where((item) => !item.isBought).toList();
    final ours = unbought.where(_isThisWeeks).firstOrNull;
    if (ours != null) {
      final isCurrent =
          ours.quantity == line.quantity && ours.sourceNote == line.note;
      (isCurrent ? added : toRefresh).add((line: line, item: ours));
      return;
    }
    if (unbought.firstOrNull case final other?) {
      onList.add((line: line, item: other));
      return;
    }
    final bought = matches.where(_isRecentPurchase).firstOrNull;
    if (bought != null) {
      recentlyBought.add((line: line, item: bought));
      return;
    }
    toAdd.add(line);
  }

  bool _isRecentPurchase(GroceryItem item) {
    if (!item.isBought) return false;
    if (_isThisWeeks(item)) return true;
    final boughtAt = item.boughtAt;
    // A tick the server has not timed yet was a moment ago.
    if (boughtAt == null) return true;
    return now.difference(boughtAt) < GroceryPlanDiff.recentlyBoughtWithin;
  }

  /// This week's unbought items from the plans whose name no plan asks for.
  List<GroceryItem> noLongerPlanned(Set<String> wanted) => [
    for (final item in items)
      if (_isThisWeeks(item) &&
          !item.isBought &&
          !wanted.contains(item.matchKey))
        item,
  ];
}
