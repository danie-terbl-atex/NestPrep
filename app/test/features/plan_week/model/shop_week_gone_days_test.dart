import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/food_rules.dart';
import 'package:nestprep/features/lunch_box/model/lunch_board.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/model/checked_product.dart';
import 'package:nestprep/features/plan_week/model/idea_search.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';
import 'package:nestprep/features/plan_week/model/plan_fallback.dart';
import 'package:nestprep/features/plan_week/model/shop_week_assembly.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/checkers_fakes_for_plan_week.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/plan_week_packing.dart';

/// *Plan my week* fills the week the board shows; on a Wednesday that is
/// this week, and Monday's to Wednesday's boxes have gone. A school day the
/// board says has happened (`LunchDay.hasHappened` — today or earlier) is
/// never planned, by the model's answer or on the phone (lunch-box
/// ADR-0019), the same rule as the server's.
void main() {
  const lwazi = LunchFixtures.lwaziId;
  final monday = LunchFixtures.week.monday;
  final wednesday = monday.addDays(2);
  final saturdayBefore = monday.addDays(-2);
  final rules = <String, FoodRules>{lwazi: LunchFixtures.lwaziEntry.foodRules};

  LunchBoard boardOn(CalendarDate today) => LunchBoard.from(
    week: LunchFixtures.week,
    today: today,
    roster: LunchFixtures.roster(),
    library: LunchFixtures.library,
    favourites: const [],
    plans: const [],
  );

  final apples = IdeaSearch(
    idea: LunchIdea.checked(
      id: 'fruit',
      slot: LunchSlot.fruit,
      idea: 'Apples',
      rulesByChild: rules,
      origin: IdeaOrigin.drafted,
    ),
    status: IdeaSearchStatus.done,
    found: [
      CheckedProduct.of(
        planWeekProduct(
          'Apples 6 pack',
          id: 'apples6',
          packCount: 6,
          ingredients: 'Apples',
        ),
        rules,
      ),
    ],
  );

  List<int> fruitDays(CalendarDate today) {
    final week = ShopWeekAssembly.fallback(
      board: boardOn(today),
      childIds: {lwazi},
      searches: [apples],
      budget: null,
      packing: packingFor({LunchSlot.fruit}),
      reason: PlanFallbackReason.offline,
    );
    return [
      for (var day = 1; day <= 5; day++)
        if (week.children.single.addedAt(day, LunchSlot.fruit) != null) day,
    ];
  }

  test('without AI, a Wednesday fills Thursday and Friday only', () {
    expect(fruitDays(wednesday), [4, 5]);
  });

  test('without AI, the Saturday before fills the whole week', () {
    expect(fruitDays(saturdayBefore), [1, 2, 3, 4, 5]);
  });

  test("the model's answer for a day that has gone is dropped", () {
    final week = ShopWeekAssembly.fromReply(
      board: boardOn(wednesday),
      childIds: {lwazi},
      searches: [apples],
      budget: null,
      packing: packingFor({LunchSlot.fruit}),
      reply: LunchWeekReply(
        lunches: [
          for (final day in [2, 3, 4])
            ReplyLunch(
              childId: lwazi,
              day: day,
              slot: LunchSlot.fruit,
              ideaId: 'fruit',
              productId: 'apples6',
            ),
        ],
        boxesPerPack: const {},
        budgetCents: null,
        dropped: 0,
        callsLeft: null,
      ),
    );
    expect(week.children.single.added.keys, [
      LunchPlan.slotKey(4, LunchSlot.fruit),
    ]);
  });
}
