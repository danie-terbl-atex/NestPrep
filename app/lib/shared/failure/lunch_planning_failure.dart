part of 'app_failure.dart';

// ---- lunch-box V2: pantry, budget, kid picks (lunch-box ADR-0006 to 0008) ----

/// Why planning from the pantry, a price or a kid's pick did not happen.
enum LunchPlanningProblem {
  /// That box was marked packed already — on this phone or another.
  alreadyPacked,

  /// The pantry did not have what the box took, or had more than it keeps:
  /// another phone changed it a moment ago.
  pantryChanged,

  /// A child is offered two or three things, not one and not a menu.
  wrongNumberOfOptions,

  /// An option was refused by the rules: not safe for the child now.
  optionNotSafe,

  /// A kid's pick was refused: it is no longer one of the options.
  notAnOption,

  /// A price or a budget the rules would not keep.
  amountOutOfRange,
}

final class LunchPlanningFailure extends AppFailure {
  const LunchPlanningFailure(this.problem);

  final LunchPlanningProblem problem;
}
