import '../../../shared/async/combine_latest.dart';
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
  ) => combineLatest2(
    _repository.watchPlans(householdId, from: week, to: week),
    _repository.watchItems(householdId),
    (plans, library) => LunchWeekItems.from(plans: plans, library: library),
  );

  /// [ownChildId] is a kid reading with the `own` grant, which opens their
  /// one plan and no other.
  Stream<Map<int, List<String>>> watchPackedDays(
    String householdId,
    LunchWeek week, {
    String? ownChildId,
  }) =>
      (ownChildId == null
              ? _repository.watchPlans(householdId, from: week, to: week)
              : _repository
                    .watchPlan(householdId, childId: ownChildId, week: week)
                    .map((plan) => [plan]))
          .map(LunchPlan.packedDaysOf);
}
