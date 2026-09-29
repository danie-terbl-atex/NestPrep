import 'package:flutter/foundation.dart';

import 'grocery_need.dart';
import 'grocery_need_reason.dart';
import 'grocery_quantity.dart';

/// One line the week's plans propose, merged from every source's needs on the
/// normalised name (groceries ADR-0002): *Bread · 2 loaves — for 5 lunches +
/// Tuesday dinner*.
@immutable
class GroceryProposal {
  const GroceryProposal({
    required this.key,
    required this.name,
    required this.quantity,
    required this.reasons,
  });

  /// The normalised name every need for it shared.
  final String key;

  /// The first spelling met — meals before lunches, as the sources are listed.
  final String name;
  final GroceryQuantity quantity;

  /// Meals in week order, then one lunch reason summing every box and child,
  /// then any other source's labels, each once.
  final List<GroceryNeedReason> reasons;

  /// The longest name a planned item may be filed under; the rules hold the
  /// same bound on `sourceKey`. Every library caps names well below it.
  static const keyLimit = 80;

  /// Merges needs into proposals, in the order their names were first met.
  static List<GroceryProposal> merge(Iterable<GroceryNeed> needs) {
    final byKey = <String, List<GroceryNeed>>{};
    for (final need in needs) {
      if (need.key.isEmpty || need.key.length > keyLimit) continue;
      byKey.putIfAbsent(need.key, () => []).add(need);
    }
    return [
      for (final MapEntry(:key, :value) in byKey.entries)
        GroceryProposal(
          key: key,
          name: value.first.name.trim(),
          quantity: GroceryQuantity.sum([
            for (final need in value) ?need.amount,
          ]),
          reasons: _mergedReasons([for (final need in value) need.reason]),
        ),
    ];
  }

  static List<GroceryNeedReason> _mergedReasons(
    List<GroceryNeedReason> reasons,
  ) {
    final meals = <MealPlanReason>{};
    final labels = <LabelledReason>{};
    var boxes = 0;
    final children = <String>[];
    for (final reason in reasons) {
      switch (reason) {
        case MealPlanReason():
          meals.add(reason);
        case LunchPlanReason(:final childIds):
          boxes += reason.boxes;
          children.addAll(childIds.where((id) => !children.contains(id)));
        case LabelledReason():
          labels.add(reason);
      }
    }
    final orderedMeals = meals.toList()
      ..sort((a, b) {
        final byDay = a.isoWeekday.compareTo(b.isoWeekday);
        return byDay != 0 ? byDay : a.slot.index.compareTo(b.slot.index);
      });
    return List.unmodifiable([
      ...orderedMeals,
      if (boxes > 0)
        LunchPlanReason(boxes: boxes, childIds: List.unmodifiable(children)),
      ...labels,
    ]);
  }
}
