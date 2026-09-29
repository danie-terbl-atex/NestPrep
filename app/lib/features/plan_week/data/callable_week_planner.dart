import 'package:cloud_functions/cloud_functions.dart';

import '../../lunch_box/model/lunch_week.dart';
import '../model/plan_week_options.dart';
import '../model/plan_week_reply.dart';
import 'plan_week_failure_mapper.dart';
import 'week_planner.dart';

/// `planMyWeek` (lunch-box ADR-0011). The Function reads the household itself
/// and answers with a proposal only; the phone sends the week and the
/// choices, never anything about a child.
final class CallableWeekPlanner implements WeekPlanner {
  const CallableWeekPlanner(this._functions);

  final FirebaseFunctions _functions;

  /// The Function's own limit is sixty seconds; the phone waits a little
  /// longer so it hears the Function's answer rather than its own timeout.
  static const _timeout = Duration(seconds: 70);

  @override
  Future<PlanWeekReply> plan({
    required String householdId,
    required LunchWeek week,
    required PlanWeekOptions options,
  }) async {
    try {
      final result = await _functions
          .httpsCallable(
            'planMyWeek',
            options: HttpsCallableOptions(timeout: _timeout),
          )
          .call<Object?>({
            'householdId': householdId,
            'week': week.key,
            'childIds': [...options.childIds]..sort(),
            'includeDinners': options.includeDinners,
            'useWhatsInTheHouse': options.useWhatsInTheHouse,
            'budget': options.budget.name,
          });
      return PlanWeekReply.fromWire(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw failureFromPlanWeekCallable(error);
    }
  }
}
