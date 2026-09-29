import 'package:flutter/foundation.dart';

import 'grocery_plan_diff.dart';
import 'grocery_plan_line.dart';

/// A new item the plans put on the list (groceries ADR-0002).
typedef PlannedItemCreate = ({
  String id,
  String name,
  String? quantity,
  String key,
  String week,
  String note,
});

/// This week's item from the plans, brought up to date.
typedef PlannedItemRefresh = ({String itemId, String? quantity, String note});

/// Exactly what one *Update the list* — or one keep-in-step pass — writes, in
/// one batch. Built from a [GroceryPlanDiff] and nothing else, so it can only
/// ever touch what the diff offered.
@immutable
class GroceryPlanChanges {
  const GroceryPlanChanges({
    this.creates = const [],
    this.refreshes = const [],
    this.removals = const [],
  });

  /// Everything the diff would change — what keep-in-step applies.
  factory GroceryPlanChanges.all(
    GroceryPlanDiff diff, {
    required Set<String> existingIds,
  }) => GroceryPlanChanges.chosen(
    diff,
    existingIds: existingIds,
    addKeys: {for (final line in diff.toAdd) line.key},
    refreshIds: {for (final match in diff.toRefresh) match.item.id},
    removeIds: {for (final item in diff.toRemove) item.id},
  );

  /// What a person left ticked in the sheet. [addKeys] may name a line from
  /// *bought recently* — adding it again is their call to make.
  factory GroceryPlanChanges.chosen(
    GroceryPlanDiff diff, {
    required Set<String> existingIds,
    required Set<String> addKeys,
    Set<String> refreshIds = const {},
    Set<String> removeIds = const {},
  }) {
    final addable = [
      ...diff.toAdd,
      for (final match in diff.recentlyBought) match.line,
    ];
    return GroceryPlanChanges(
      creates: [
        for (final line in addable)
          if (addKeys.contains(line.key)) _create(line, diff.week, existingIds),
      ],
      refreshes: [
        for (final (:line, :item) in diff.toRefresh)
          if (refreshIds.contains(item.id))
            (itemId: item.id, quantity: line.quantity, note: line.note),
      ],
      removals: [
        for (final item in diff.toRemove)
          if (removeIds.contains(item.id)) item.id,
      ],
    );
  }

  final List<PlannedItemCreate> creates;
  final List<PlannedItemRefresh> refreshes;
  final List<String> removals;

  bool get isEmpty => creates.isEmpty && refreshes.isEmpty && removals.isEmpty;

  int get count => creates.length + refreshes.length + removals.length;

  /// Longer than any real name needs, well inside Firestore's id limit.
  static const _slugLimit = 80;

  /// The id a planned item takes: the same on every phone for the same week and
  /// name, so two lists kept in step write one document, not two. Letters and
  /// digits in any script survive; anything else becomes one dash.
  static String idFor(String week, String key) {
    final slug = key
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final bounded = slug.length > _slugLimit
        ? slug.substring(0, _slugLimit)
        : slug;
    return 'plan-$week-${bounded.isEmpty ? 'item' : bounded}';
  }

  static PlannedItemCreate _create(
    GroceryPlanLine line,
    String week,
    Set<String> existingIds,
  ) {
    final preferred = idFor(week, line.key);
    // Taken by this week's item already bought: adding it again is a new line
    // beside it, never a write over the history.
    var id = preferred;
    for (var copy = 2; existingIds.contains(id); copy++) {
      id = '$preferred-$copy';
    }
    return (
      id: id,
      name: line.name,
      quantity: line.quantity,
      key: line.key,
      week: week,
      note: line.note,
    );
  }
}
