import '../failure/app_failure.dart';

/// The words lunch-box's V2 tools share (lunch-box ADR-0006 to ADR-0008):
/// the way in from the lunch board and the refusals. Each tool's own words
/// are in its own file beside this one (`FE-19`).
abstract final class LunchPlanningCopy {
  static const openPantry = 'Pantry';
  static const openBudget = 'Budget';
  static const openKidPicks = 'Kid picks';
  static const premiumHint = 'Premium';

  static String problem(LunchPlanningProblem problem) => switch (problem) {
    LunchPlanningProblem.alreadyPacked =>
      'That box is already marked packed — perhaps on another phone.',
    LunchPlanningProblem.pantryChanged =>
      'The pantry changed on another phone a moment ago. Have another look '
          'and try again.',
    LunchPlanningProblem.wrongNumberOfOptions =>
      'Pick two or three things to choose from.',
    LunchPlanningProblem.optionNotSafe =>
      'One of those is not safe for them any more. Their allergies or '
          'school rules may have just changed.',
    LunchPlanningProblem.notAnOption =>
      'That one is not on the menu any more. Ask a grown-up to have a look.',
    LunchPlanningProblem.amountOutOfRange =>
      'That amount is not one NestPrep can keep. Check it and try again.',
  };
}
