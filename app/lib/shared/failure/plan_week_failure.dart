part of 'app_failure.dart';

// ---- plan my week with AI (lunch-box ADR-0011) ----

/// Why a week could not be planned or saved. The first four are the server's
/// `PLAN_WEEK_REFUSALS`; the last is the phone's.
enum PlanWeekProblem {
  /// The `planMyWeek` switch is off.
  planWeekOff,

  /// This person may look at lunches but not change them.
  lunchNotShared,

  /// No child chosen, and no dinners either.
  nothingToPlan,

  /// A week that has gone, or is not one.
  weekNotPlannable,

  /// Some of the plan was saved and some was refused — a child's rules
  /// changed on another phone in the meantime, say.
  partlySaved,
}

final class PlanWeekFailure extends AppFailure {
  const PlanWeekFailure(this.problem);

  final PlanWeekProblem problem;
}
