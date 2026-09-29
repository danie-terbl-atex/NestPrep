import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget_week.dart';
import 'package:nestprep/features/lunch_box/model/lunch_price.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';

/// Budget mode's controller (lunch-box ADR-0007): it joins the prices and
/// the budget with the board, keeps amounts inside what the rules keep, and
/// hears a rules refusal as premium being needed.
void main() {
  late LunchPlanningHarness harness;

  setUp(() => harness = LunchPlanningHarness());
  tearDown(() => harness.close());

  Future<void> arrive({
    List<LunchPrice> prices = const [],
    LunchBudget? budget,
  }) async {
    harness.lunch.emit(plans: [LunchFixtures.plan(LunchFixtures.ayandaId)]);
    harness.emitPlanning(prices: prices, budget: budget);
    await pumpEventQueue();
  }

  LunchBudgetWeek week() =>
      (harness.budget.week as AsyncData<LunchBudgetWeek>).value;

  test(
    'publishes once the board, the prices and the budget have answered',
    () async {
      expect(harness.budget.week, isA<AsyncLoading<LunchBudgetWeek>>());
      await arrive(
        prices: [
          const LunchPrice(
            id: 'apple',
            cents: 450,
            updatedBy: Fixtures.samMemberId,
          ),
        ],
        budget: const LunchBudget(
          id: 'weekly',
          cents: 25000,
          updatedBy: 'm-sam',
        ),
      );
      expect(week().priceOf('apple')?.cents, 450);
      expect(week().reading?.budget, const Money(25000));
    },
  );

  test(
    'a price and a budget are written in whole cents, in the viewer’s name',
    () async {
      await arrive();
      await harness.budget.setPrice(itemId: 'wrap', cents: 4200, portions: 8);
      await harness.budget.setBudget(25000);
      final price = harness.budgetRepository.setPrices.single;
      expect(
        (price.itemId, price.cents, price.portions, price.updatedBy),
        ('wrap', 4200, 8, Fixtures.samMemberId),
      );
      expect(harness.budgetRepository.setBudgets.single.cents, 25000);
    },
  );

  test('refuses an amount the rules would not keep, before writing', () async {
    await arrive();
    await harness.budget.setPrice(itemId: 'wrap', cents: 500001, portions: 1);
    await harness.budget.setPrice(itemId: 'wrap', cents: 100, portions: 0);
    await harness.budget.setBudget(50);
    expect(harness.budgetRepository.setPrices, isEmpty);
    expect(harness.budgetRepository.setBudgets, isEmpty);
    expect(
      (harness.budget.actionFailure as LunchPlanningFailure?)?.problem,
      LunchPlanningProblem.amountOutOfRange,
    );
  });

  test(
    'a refusal from the rules is premium being needed, on budget mode',
    () async {
      await arrive();
      harness.budgetRepository.failWritesWith = const PermissionDeniedFailure();
      await harness.budget.setBudget(25000);
      expect(
        (harness.budget.actionFailure as PremiumRequiredFailure?)?.feature,
        PremiumFeature.budgetMode,
      );
    },
  );

  test('removing a price or the budget is not premium-gated here', () async {
    await arrive();
    await harness.budget.clearPrice('apple');
    await harness.budget.clearBudget();
    expect(harness.budgetRepository.clearedPrices, ['apple']);
    expect(harness.budgetRepository.budgetsCleared, 1);
  });

  test('a failed read is the budget’s failure; retry reads again', () async {
    harness.budgetRepository.failPricesWith(const UnavailableFailure());
    await arrive();
    expect(harness.budget.week, isA<AsyncFailure<LunchBudgetWeek>>());
    await harness.budget.retry();
    expect(harness.budget.week, isA<AsyncLoading<LunchBudgetWeek>>());
  });
}
