import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/food_rules.dart';
import 'package:nestprep/features/lunch_box/model/lunch_board.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget_week.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_price.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week_cost.dart';
import 'package:nestprep/features/plan_week/model/checked_product.dart';
import 'package:nestprep/features/plan_week/model/idea_search.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';
import 'package:nestprep/features/plan_week/model/plan_fallback.dart';
import 'package:nestprep/features/plan_week/model/shop_week.dart';
import 'package:nestprep/features/plan_week/model/shop_week_assembly.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/checkers_fakes_for_plan_week.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/plan_week_packing.dart';

/// The bug Daniel saw on 2026-10-07: *Plan my week* read the whole weekly
/// budget against only the lunches it added, so a week already holding R300
/// of R500 was planned to R500 more, said "within budget", and the budget
/// screen then read R800. The household's week is one basket (lunch-box
/// ADR-0012 §4): what is packed already, for every child, and what the plan
/// adds, rounded to whole packs together — the total the meter will show.
void main() {
  const lwazi = LunchFixtures.lwaziId;
  const ayanda = LunchFixtures.ayandaId;
  String key(int day, LunchSlot slot) => LunchPlan.slotKey(day, slot);
  final rules = <String, FoodRules>{
    lwazi: LunchFixtures.lwaziEntry.foodRules,
    ayanda: LunchFixtures.ayandaEntry.foodRules,
  };
  // The Saturday before the week: no school day of it has gone.
  final saturday = LunchFixtures.week.monday.addDays(-2);
  LunchPrice price(String itemId, int cents, [int portions = 1]) =>
      LunchPrice(id: itemId, cents: cents, portions: portions, updatedBy: 'm');

  // Bought by an earlier plan: the library item a shop yoghurt became.
  final yoghurtItem = LunchFixtures.item(
    'yog-item',
    'Fruit yoghurt 6 x 100g',
    LunchSlot.snack,
  );
  final library = [...LunchFixtures.library, yoghurtItem];

  LunchBoard boardOf(List<LunchPlan> plans, {List<LunchItem>? items}) =>
      LunchBoard.from(
        week: LunchFixtures.week,
        today: saturday,
        roster: LunchFixtures.roster(),
        library: items ?? library,
        favourites: const [],
        plans: plans,
      );

  // Lwazi's week, already packed: a R60 wrap every day (R300) and one of
  // the yoghurts on Monday.
  final lwazisWeek = LunchFixtures.plan(
    lwazi,
    slots: {
      key(1, LunchSlot.snack): LunchPick.of(yoghurtItem),
      for (var day = 1; day <= 5; day++)
        key(day, LunchSlot.main): LunchPick.of(LunchFixtures.wrap),
    },
  );
  final pricesBefore = {
    'yog-item': price('yog-item', 3600, 6),
    'wrap': price('wrap', 6000),
  };

  IdeaSearch searched(String id, List<CheckedProduct> found) => IdeaSearch(
    idea: LunchIdea.checked(
      id: id,
      slot: LunchSlot.snack,
      idea: id,
      rulesByChild: rules,
      origin: IdeaOrigin.drafted,
    ),
    status: IdeaSearchStatus.done,
    found: found,
  );
  final yoghurt = CheckedProduct.of(
    planWeekProduct(
      'Fruit yoghurt 6 x 100g',
      id: 'yog',
      cents: 3600,
      packCount: 6,
      ingredients: 'Milk, fruit',
    ),
    rules,
  );
  final rusks = CheckedProduct.of(
    planWeekProduct('Rusks', id: 'rusk', cents: 4500, ingredients: 'Oats'),
    rules,
  );

  /// Ayanda's snacks planned without AI: yoghurt, rusks, yoghurt, rusks,
  /// yoghurt — read against budget mode's picture of the week before.
  ShopWeek planAyandasSnacks({LunchBudgetWeek? weekSoFar}) {
    final before = boardOf([lwazisWeek]);
    return ShopWeekAssembly.fallback(
      board: before,
      childIds: {ayanda},
      searches: [
        searched('yoghurts', [yoghurt]),
        searched('rusks', [rusks]),
      ],
      budget: const Money(50000),
      packing: packingFor({LunchSlot.snack}),
      reason: PlanFallbackReason.offline,
      weekSoFar:
          weekSoFar ??
          LunchBudgetWeek(
            board: before,
            prices: pricesBefore,
            budget: const LunchBudget(
              id: 'weekly',
              cents: 50000,
              updatedBy: 'm',
            ),
          ),
    );
  }

  test('reads what is packed already and what the plan adds against the '
      'weekly budget, a shared product in whole packs together', () {
    final plan = planAyandasSnacks();
    // R300 of wraps already in; the yoghurt packed on Monday and the three
    // the plan adds are four boxes of one six-pack (R36); two rusks (R90).
    expect(plan.reading!.spent, const Money(30000 + 3600 + 9000));
    expect(plan.reading!.budget, const Money(50000));
    // What to buy is still only the plan's own products.
    expect(plan.basket.total, const Money(3600 + 9000));
  });

  test('is the total the budget screen shows once the week is used', () {
    final plan = planAyandasSnacks();
    final rusksItem = LunchFixtures.item('rusk-item', 'Rusks', LunchSlot.snack);
    // The week as *Use it* writes it: the yoghurt reuses the library's item,
    // the rusks become a new one, and each takes the shelf price.
    final after = boardOf(
      [
        lwazisWeek,
        LunchFixtures.plan(
          ayanda,
          slots: {
            for (final day in [1, 3, 5])
              key(day, LunchSlot.snack): LunchPick.of(yoghurtItem),
            for (final day in [2, 4])
              key(day, LunchSlot.snack): LunchPick.of(rusksItem),
          },
        ),
      ],
      items: [...library, rusksItem],
    );
    final meter = LunchWeekCost.of(
      board: after,
      prices: {
        ...pricesBefore,
        'yog-item': price('yog-item', 3600, plan.boxesPerPackOf('yog')),
        'rusk-item': price('rusk-item', 4500, plan.boxesPerPackOf('rusk')),
      },
    );
    expect(plan.reading!.spent, meter.basket.total);
  });

  test('a picture of another week is not counted', () {
    final otherWeek = LunchBoard.from(
      week: LunchFixtures.week.next,
      today: saturday,
      roster: LunchFixtures.roster(),
      library: library,
      favourites: const [],
      plans: [LunchFixtures.plan(lwazi, week: LunchFixtures.week.next)],
    );
    final plan = planAyandasSnacks(
      weekSoFar: LunchBudgetWeek(
        board: otherWeek,
        prices: pricesBefore,
        budget: null,
      ),
    );
    expect(plan.reading!.spent, plan.basket.total);
  });
}
