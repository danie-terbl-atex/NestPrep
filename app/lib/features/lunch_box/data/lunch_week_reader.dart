import 'dart:async';

import '../model/lunch_item.dart';
import '../model/lunch_plan.dart';
import '../model/lunch_week.dart';
import '../model/lunch_week_items.dart';
import 'lunch_repository.dart';

/// The read API other features consume (lunch-box overview, *Contracts*):
/// everything one household week's lunch boxes need, one row per item,
/// summed across every child. Groceries phase 2 fills its list from it; the
/// shareable card (lunch-box phase 2) draws one child's week from
/// `LunchRepository.watchPlan` instead.
///
/// Two listeners — the week's plans and the library — joined here so no
/// reader joins them twice. It needs the `lunch` grant at `view` or `edit`;
/// a reader without it gets `PermissionDeniedFailure`.
final class LunchWeekReader {
  const LunchWeekReader(this._repository);

  final LunchRepository _repository;

  Stream<List<LunchWeekItem>> watchWeekItems(
    String householdId,
    LunchWeek week,
  ) {
    late final StreamController<List<LunchWeekItem>> output;
    StreamSubscription<List<LunchPlan>>? plans;
    StreamSubscription<List<LunchItem>>? items;
    List<LunchPlan>? latestPlans;
    List<LunchItem>? latestItems;

    void publish() {
      final (planList, itemList) = (latestPlans, latestItems);
      if (planList == null || itemList == null) return;
      output.add(LunchWeekItems.from(plans: planList, library: itemList));
    }

    output = StreamController<List<LunchWeekItem>>(
      onListen: () {
        plans = _repository
            .watchPlans(householdId, from: week, to: week)
            .listen((value) {
              latestPlans = value;
              publish();
            }, onError: output.addError);
        items = _repository.watchItems(householdId).listen((value) {
          latestItems = value;
          publish();
        }, onError: output.addError);
      },
      onCancel: () async {
        await plans?.cancel();
        await items?.cancel();
      },
    );
    return output.stream;
  }
}
