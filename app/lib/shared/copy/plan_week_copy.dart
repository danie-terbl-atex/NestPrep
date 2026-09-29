import '../../features/plan_week/model/planned_week.dart';
import '../failure/app_failure.dart';

/// Every word *Plan my week* says (`FE-19`, lunch-box ADR-0011).
abstract final class PlanWeekCopy {
  // ---- the way in, on the lunch board ----
  static const entryTitle = 'Plan my week';
  static const entryBody =
      'Lunches for every child, the family’s dinners and the shopping list '
      '— in one tap.';
  static const entryAction = 'Plan my week';
  static const premiumTag = 'Premium';

  // ---- choosing ----
  static const title = 'Plan my week';
  static const chooseHeadline = 'What shall we plan?';
  static const chooseBody =
      'NestPrep plans around each child’s allergies, the nut rule and what '
      'they actually eat. You look it over before anything is saved.';
  static const lunchesFor = 'Lunches for';
  static const noChildren =
      'Nobody is marked as a child yet — dinners can still be planned.';
  static const dinnersTitle = 'Dinners too';
  static const dinnersOn =
      'Seven dinners from your own meals, and a new idea or two.';
  static const dinnersOff = 'Only lunches this time.';
  static const pantryTitle = 'Use what’s in the house';
  static const pantryBody = 'Pack from the pantry first.';
  static const budgetTitle = 'Keep it thrifty';
  static const budgetBody =
      'Lean towards what costs least, where you priced things.';
  static const planAction = 'Plan my week';
  static const privacyNote =
      'The planner sees item and meal names only — never a name, an allergy '
      'or anything medical.';

  // ---- planning ----
  static const planningTitle = 'Planning your week…';
  static const planningLine =
      'Matching favourites, checking every box against each child’s rules.';
  static const planningOrbitLabel = 'Your week is being planned';

  // ---- review ----
  static const reviewTitle = 'Your week, planned';
  static String reviewSummary(int lunches, int dinners) =>
      '${_count(lunches, 'lunch compartment', 'lunch compartments')} and '
      '${_count(dinners, 'dinner', 'dinners')} ready to go.';
  static const madeByAi = 'Planned with AI';
  static const madeWithoutAi = 'Planned without AI';
  static String fallbackBody(PlanFallbackReason reason) => switch (reason) {
    PlanFallbackReason.aiOff =>
      'AI planning is paused, so this week comes from your go-to boxes, what '
          'each child eats and your own meals.',
    PlanFallbackReason.aiLimitReached =>
      'This month’s AI plans are used up — they come back on the 1st. '
          'Meanwhile this week comes from your go-to boxes and your own meals.',
    PlanFallbackReason.aiUnavailable =>
      'The planner did not answer, so this week comes from your go-to boxes, '
          'what each child eats and your own meals.',
    PlanFallbackReason.offline =>
      'You look offline, so this week was planned on your phone from your '
          'go-to boxes and your own meals.',
  };
  static String callsLeft(int calls) => switch (calls) {
    0 => 'That was this month’s last AI plan.',
    1 => '1 AI plan left this month.',
    _ => '$calls AI plans left this month.',
  };
  static String dropped(int count) =>
      '${_count(count, 'suggestion was', 'suggestions were')} left out '
      'because it did not fit a child’s rules.';
  static const nothingToAdd = 'This week is already planned';
  static const nothingToAddBody =
      'Every compartment and dinner is filled. Empty a few and plan again, '
      'or look at next week.';
  static const lunchesHeader = 'Lunches';
  static const dinnersHeader = 'Dinners';
  static const alreadyPacked = 'Already packed';
  static const tapToSwap = 'Tap anything new to swap it.';
  static String newForChild(int count) =>
      count == 0 ? 'Nothing new' : '$count new';
  static const originSuggested = 'Suggested';
  static const originFilled = 'From your usuals';
  static const originSwapped = 'Your pick';
  static const newIdeaCheck =
      'Check the ingredients against everybody’s allergies before you cook.';
  static const alreadyPlanned = 'Already planned';
  static const noDinner = 'Nothing planned';
  static String ingredientsLine(int count) =>
      _count(count, 'ingredient', 'ingredients');
  static const useAction = 'Use this plan';
  static const startOver = 'Start over';
  static const saving = 'Saving your week…';

  // ---- swapping a dinner ----
  static String dinnerSheetTitle(String day) => 'Dinner on $day';
  static const keepIdea = 'Keep the new idea';
  static const leaveEmpty = 'Leave it empty';
  static const fromYourMeals = 'From your meals';
  static const noMeals = 'No meals in your library yet.';

  // ---- done ----
  static const doneTitle = 'Your week is planned';
  static String doneBody(int lunches, int dinners) =>
      '${_count(lunches, 'compartment', 'compartments')} packed and '
      '${_count(dinners, 'dinner', 'dinners')} on the meal plan.';
  static String skipped(int count) =>
      '${_count(count, 'thing was', 'things were')} left out — filled by '
      'somebody else meanwhile, or no longer right for a child.';
  static String addIngredients(int count) =>
      'Shop for ${_count(count, 'new ingredient', 'new ingredients')}';

  /// Why a new dinner's ingredient is on the grocery list, as the list shows
  /// it.
  static const groceryNote = 'For a new dinner in this week’s plan';

  static String ingredientsAdded(int count) => count == 0
      ? 'Everything was on the shopping list already.'
      : '${_count(count, 'thing', 'things')} added to the shopping list.';
  static const addPantryShortfall = 'Shop for what the pantry lacks';
  static const seeLunches = 'See the lunches';
  static const planAnother = 'Plan again';

  static String problem(PlanWeekProblem problem) => switch (problem) {
    PlanWeekProblem.planWeekOff => 'Planning the week is switched off for now.',
    PlanWeekProblem.lunchNotShared =>
      'You can look at lunches here, but not plan them.',
    PlanWeekProblem.nothingToPlan => 'Choose a child, or dinners, to plan.',
    PlanWeekProblem.weekNotPlannable =>
      'That week has gone. Plan this week or next.',
    PlanWeekProblem.partlySaved =>
      'Some of the plan could not be saved. The rest is in.',
  };

  static String _count(int count, String one, String many) =>
      count == 1 ? '1 $one' : '$count $many';
}
