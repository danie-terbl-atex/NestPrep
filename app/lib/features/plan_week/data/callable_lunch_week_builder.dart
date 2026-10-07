import 'package:cloud_functions/cloud_functions.dart';

import '../../lunch_box/model/lunch_week.dart';
import '../model/idea_search.dart';
import '../model/lunch_week_reply.dart';
import '../model/packing_preference.dart';
import 'lunch_week_builder.dart';
import 'lunch_week_request.dart';
import 'plan_week_failure_mapper.dart';

/// `buildLunchWeek` (lunch-box ADR-0012). The Function checks every product
/// against each child's rules again before the model sees it, and every
/// choice after.
final class CallableLunchWeekBuilder implements LunchWeekBuilder {
  const CallableLunchWeekBuilder(this._functions);

  final FirebaseFunctions _functions;

  static const _timeout = Duration(seconds: 70);

  @override
  Future<LunchWeekReply> build({
    required String householdId,
    required LunchWeek week,
    required Set<String> childIds,
    required List<IdeaSearch> searches,
    required PackingChoice packing,
  }) async {
    try {
      final result = await _functions
          .httpsCallable(
            'buildLunchWeek',
            options: HttpsCallableOptions(timeout: _timeout),
          )
          .call<Object?>(
            LunchWeekRequest.toWire(
              householdId: householdId,
              week: week,
              childIds: childIds,
              searches: searches,
              packing: packing,
            ),
          );
      return LunchWeekReply.fromWire(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw failureFromPlanWeekCallable(error);
    }
  }
}
