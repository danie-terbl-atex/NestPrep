import 'grocery_plan_diff.dart';

/// What a person has ticked in *From this week's plans* (groceries ADR-0002).
///
/// Held as what they changed from the defaults rather than as a list of what
/// is ticked, because the sheet is live: a meal planned on another phone while
/// it is open appears ticked, the way every new line does, without anybody's
/// earlier choices being lost. Adds, refreshes and removals start ticked;
/// *bought recently* starts unticked.
class GroceryPlanSelection {
  final _untickedAdds = <String>{};
  final _untickedRefreshes = <String>{};
  final _untickedRemovals = <String>{};
  final _addAgain = <String>{};

  bool isAddTicked(String key) => !_untickedAdds.contains(key);
  bool isRefreshTicked(String itemId) => !_untickedRefreshes.contains(itemId);
  bool isRemovalTicked(String itemId) => !_untickedRemovals.contains(itemId);
  bool isAddAgainTicked(String key) => _addAgain.contains(key);

  void toggleAdd(String key) => _toggle(_untickedAdds, key);
  void toggleRefresh(String itemId) => _toggle(_untickedRefreshes, itemId);
  void toggleRemoval(String itemId) => _toggle(_untickedRemovals, itemId);
  void toggleAddAgain(String key) => _toggle(_addAgain, key);

  /// Ticks every change the plans offer, or unticks every one — *bought
  /// recently* included both ways.
  void setAll(GroceryPlanDiff diff, {required bool ticked}) {
    _untickedAdds.clear();
    _untickedRefreshes.clear();
    _untickedRemovals.clear();
    _addAgain.clear();
    if (ticked) {
      _addAgain.addAll([
        for (final match in diff.recentlyBought) match.line.key,
      ]);
      return;
    }
    _untickedAdds.addAll([for (final line in diff.toAdd) line.key]);
    _untickedRefreshes.addAll([
      for (final match in diff.toRefresh) match.item.id,
    ]);
    _untickedRemovals.addAll([for (final item in diff.toRemove) item.id]);
  }

  /// What is ticked among what [diff] offers now.
  ({Set<String> addKeys, Set<String> refreshIds, Set<String> removeIds})
  chosenFrom(GroceryPlanDiff diff) => (
    addKeys: {
      for (final line in diff.toAdd)
        if (isAddTicked(line.key)) line.key,
      for (final match in diff.recentlyBought)
        if (isAddAgainTicked(match.line.key)) match.line.key,
    },
    refreshIds: {
      for (final match in diff.toRefresh)
        if (isRefreshTicked(match.item.id)) match.item.id,
    },
    removeIds: {
      for (final item in diff.toRemove)
        if (isRemovalTicked(item.id)) item.id,
    },
  );

  int countIn(GroceryPlanDiff diff) {
    final chosen = chosenFrom(diff);
    return chosen.addKeys.length +
        chosen.refreshIds.length +
        chosen.removeIds.length;
  }

  /// Whether anything offered is still unticked — what decides between
  /// *Tick all* and *Untick all*.
  bool hasUntickedIn(GroceryPlanDiff diff) =>
      countIn(diff) <
      diff.toAdd.length +
          diff.toRefresh.length +
          diff.toRemove.length +
          diff.recentlyBought.length;

  static void _toggle(Set<String> set, String value) {
    if (!set.remove(value)) set.add(value);
  }
}
