import '../../household/model/household_area.dart';
import '../../lunch_box/data/lunch_week_reader.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../../lunch_box/model/lunch_week_items.dart';
import '../model/grocery_need.dart';
import '../model/grocery_need_reason.dart';
import 'grocery_suggestion_source.dart';

/// The week's lunch boxes as grocery needs, through lunch-box's read API
/// (`LunchWeekReader.watchWeekItems`, lunch-box overview *Contracts*): one need
/// per item, already summed across every day and child, counted in boxes and
/// never converted to an amount (groceries ADR-0003).
///
/// The Sunday prep list reads the same rows for a different question — what
/// to make ahead — so the two never disagree about what the week holds.
final class LunchPlanGrocerySource implements GrocerySuggestionSource {
  const LunchPlanGrocerySource(this._reader);

  final LunchWeekReader _reader;

  @override
  String get id => 'lunch';

  @override
  HouseholdArea get area => HouseholdArea.lunch;

  @override
  Stream<List<GroceryNeed>> watchNeeds(String householdId, LunchWeek week) =>
      _reader.watchWeekItems(householdId, week).map(needsOf);

  static List<GroceryNeed> needsOf(List<LunchWeekItem> items) => [
    for (final item in items)
      if (item.portions > 0 && item.name.trim().isNotEmpty)
        GroceryNeed(
          name: item.name,
          reason: LunchPlanReason(
            boxes: item.portions,
            childIds: item.childIds,
          ),
        ),
  ];
}
