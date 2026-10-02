import '../../../shared/failure/app_failure.dart';

/// Who made a step's answer (lunch-box ADR-0012): the model, or — when AI is
/// off, spent or not answering — the phone, said so on screen.
enum PlanSource { ai, fallback }

/// Why a step was answered without AI.
enum PlanFallbackReason {
  aiOff,
  aiLimitReached,
  aiUnavailable,
  offline;

  /// The failures the phone answers itself; anything else — premium, a
  /// refusal of the plan's own — is said as it is, so null.
  static PlanFallbackReason? of(AppFailure failure) => switch (failure) {
    AiFailure(problem: AiProblem.aiSwitchedOff) ||
    PlanWeekFailure(problem: PlanWeekProblem.planWeekOff) => aiOff,
    AiFailure(problem: AiProblem.aiLimitReached) => aiLimitReached,
    AiFailure() => aiUnavailable,
    UnavailableFailure() => offline,
    _ => null,
  };
}
