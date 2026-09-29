import '../../lunch_box/model/lunch_week.dart';
import '../model/plan_week_options.dart';
import '../model/plan_week_reply.dart';

/// Asks for a week's plan (lunch-box ADR-0011). Behind an interface so a
/// widget test decides what comes back without Functions (`FE-20`).
///
/// It writes nothing: the reply is a proposal. A refusal arrives as an
/// `AppFailure` — `AiFailure` when the model could not help (switched off,
/// spent, not answering), `PremiumRequiredFailure` without premium,
/// `PlanWeekFailure` for the plan's own reasons.
abstract interface class WeekPlanner {
  Future<PlanWeekReply> plan({
    required String householdId,
    required LunchWeek week,
    required PlanWeekOptions options,
  });
}
