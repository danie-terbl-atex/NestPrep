import 'package:cloud_functions/cloud_functions.dart';

import '../../lunch_box/model/lunch_week.dart';
import '../model/lunch_ideas_reply.dart';
import 'lunch_idea_drafter.dart';
import 'plan_week_failure_mapper.dart';

/// `draftLunchIdeas` (lunch-box ADR-0012). The Function reads the household
/// itself, strikes out what a child must not have, and answers with ideas —
/// told what the lunchbox aisle already offers (ADR-0013).
final class CallableLunchIdeaDrafter implements LunchIdeaDrafter {
  const CallableLunchIdeaDrafter(this._functions);

  final FirebaseFunctions _functions;

  /// The Function's own limit is sixty seconds; the phone waits a little
  /// longer so it hears the Function's answer rather than its own timeout.
  static const _timeout = Duration(seconds: 70);

  /// The contract's bounds on the aisle (lunch-box ADR-0013).
  static const _shelfLimit = 12;
  static const _namesPerShelf = 6;

  @override
  Future<LunchIdeasReply> draft({
    required String householdId,
    required LunchWeek week,
    required Set<String> childIds,
    List<AisleShelfNames> aisle = const [],
  }) async {
    try {
      final result = await _functions
          .httpsCallable(
            'draftLunchIdeas',
            options: HttpsCallableOptions(timeout: _timeout),
          )
          .call<Object?>({
            'householdId': householdId,
            'week': week.key,
            'childIds': [...childIds]..sort(),
            'aisle': [
              for (final shelf in aisle.take(_shelfLimit))
                {
                  'slot': shelf.slot.name,
                  'title': _cut(shelf.title, 60),
                  'products': [
                    for (final name in shelf.products.take(_namesPerShelf))
                      _cut(name, 120),
                  ],
                },
            ],
          });
      return LunchIdeasReply.fromWire(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw failureFromPlanWeekCallable(error);
    }
  }

  static String _cut(String text, int longest) =>
      text.length <= longest ? text : text.substring(0, longest);
}
