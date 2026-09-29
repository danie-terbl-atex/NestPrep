import '../../household/model/household_area.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../model/grocery_need.dart';

/// Anything that wants to put things on the grocery list (groceries
/// ADR-0004). The meal plan and the lunch boxes are the first two; home-care's
/// product stock tracker ("running low") plugs in the same way.
///
/// **To plug one in:** implement this, and add one line to
/// `groceryPlanSources` in `lib/app/grocery_route.dart`. The groceries feature
/// does the rest — it reads the source only for a viewer whose grant covers
/// [area], merges its needs by normalised name with everybody else's, never
/// proposes what is on the list or usually in the house, shows the needs with
/// their reasons in *From this week's plans*, and with *keep the list in step*
/// adds and takes them off under the same rules as the plans. A source never
/// writes a grocery item itself.
///
/// **The contract:**
/// - emit a fresh list whenever what the household needs changes, and an
///   empty list when it needs nothing — the sheet waits for every visible
///   source's first emission, so a source that never emits holds it loading;
/// - give each need one reason: a `LabelledReason` with a label from the
///   plug-in's own copy file ("Running low") unless it is a plan;
/// - fail the stream with an `AppFailure` rather than swallowing an error;
/// - read nothing its [area] grant does not cover.
abstract interface class GrocerySuggestionSource {
  /// Stable and unique: `meals`, `lunch`, `homeCareStock`.
  String get id;

  /// The grant a viewer needs, at view or edit, to see what this source says.
  HouseholdArea get area;

  /// What the household needs for [week] — the household week the list is
  /// being filled for (`LunchWeek.planningFor(today)`).
  Stream<List<GroceryNeed>> watchNeeds(String householdId, LunchWeek week);
}
