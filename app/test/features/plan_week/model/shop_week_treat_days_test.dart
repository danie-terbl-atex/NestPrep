import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/food_rules.dart';
import 'package:nestprep/features/lunch_box/model/lunch_board.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/data/lunch_ideas_request.dart';
import 'package:nestprep/features/plan_week/data/lunch_week_request.dart';
import 'package:nestprep/features/plan_week/model/checked_product.dart';
import 'package:nestprep/features/plan_week/model/idea_search.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';
import 'package:nestprep/features/plan_week/model/plan_fallback.dart';
import 'package:nestprep/features/plan_week/model/shop_week.dart';
import 'package:nestprep/features/plan_week/model/shop_week_assembly.dart';
import 'package:nestprep/features/plan_week/model/treat_days.dart';

import '../../../support/checkers_fakes_for_plan_week.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/plan_week_packing.dart';

/// *Plan my week* packs a treat only on the brief's treat days (lunch-box
/// ADR-0025): they go to both callables, and the phone checks the server's
/// week against them and builds its own week from them — Friday when the
/// parent never chose.
void main() {
  const lwazi = LunchFixtures.lwaziId;
  const ayanda = LunchFixtures.ayandaId;
  final every = {...LunchSlot.values};
  final rules = <String, FoodRules>{
    lwazi: LunchFixtures.lwaziEntry.foodRules,
    ayanda: LunchFixtures.ayandaEntry.foodRules,
  };

  // Seen from the Saturday before, so every school day can be planned.
  final board = LunchBoard.from(
    week: LunchFixtures.week,
    today: LunchFixtures.week.monday.addDays(-2),
    roster: LunchFixtures.roster(),
    library: LunchFixtures.library,
    favourites: const [],
    plans: const [],
  );

  final muffins = CheckedProduct.of(
    planWeekProduct(
      'Oat muffins 6 pack',
      id: 'muffins',
      cents: 3000,
      packCount: 6,
      ingredients: 'Oats',
    ),
    rules,
  );
  final treats = [
    IdeaSearch(
      idea: LunchIdea.checked(
        id: 'treats',
        slot: LunchSlot.treat,
        idea: 'treats',
        rulesByChild: rules,
        origin: IdeaOrigin.drafted,
      ),
      status: IdeaSearchStatus.done,
      found: [muffins],
    ),
  ];

  Set<int> treatDaysOf(ShopWeek week, String childId) => {
    for (final key
        in week.children
            .firstWhere((child) => child.childId == childId)
            .added
            .keys)
      if (key.endsWith(LunchSlot.treat.name)) int.parse(key.split('_').first),
  };

  ShopWeek fromModel(Set<int> treatDays) => ShopWeekAssembly.fromReply(
    board: board,
    childIds: {lwazi},
    searches: treats,
    budget: null,
    packing: packingFor(every, treatDays: treatDays),
    reply: LunchWeekReply(
      lunches: [
        for (var day = 1; day <= 5; day++)
          ReplyLunch(
            childId: lwazi,
            day: day,
            slot: LunchSlot.treat,
            ideaId: 'treats',
            productId: 'muffins',
          ),
      ],
      boxesPerPack: const {},
      budgetCents: null,
      dropped: 0,
      callsLeft: null,
    ),
  );

  ShopWeek onThePhone(Set<int> treatDays) => ShopWeekAssembly.fallback(
    board: board,
    childIds: {lwazi, ayanda},
    searches: treats,
    budget: null,
    packing: packingFor(every, treatDays: treatDays),
    reason: PlanFallbackReason.offline,
  );

  group('the server’s week, checked on the phone', () {
    test('keeps a treat only on a chosen day', () {
      expect(treatDaysOf(fromModel({1, 3}), lwazi), {1, 3});
    });

    test('keeps Friday’s alone when the parent never chose', () {
      expect(treatDaysOf(fromModel(TreatDays.fridayOnly), lwazi), {5});
    });

    test('keeps none when no day was chosen', () {
      expect(fromModel(const {}).isEmpty, isTrue);
    });
  });

  group('a week built on the phone', () {
    test('packs a treat on every chosen day for every child', () {
      final week = onThePhone({2, 3, 4});
      expect(treatDaysOf(week, lwazi), {2, 3, 4});
      expect(treatDaysOf(week, ayanda), {2, 3, 4});
    });

    test('packs no treat with no day chosen', () {
      expect(onThePhone(const {}).isEmpty, isTrue);
    });
  });

  test('the week remembers its treat days through a swap, so an empty treat '
      'shows only on a treat day', () {
    final swapped = onThePhone({1, 4})
        .withPick(lwazi, LunchPlan.slotKey(1, LunchSlot.treat), null);
    expect(swapped.treatDays, {1, 4});
    expect(swapped.fills(1, LunchSlot.treat), isTrue);
    expect(swapped.fills(2, LunchSlot.treat), isFalse);
    expect(swapped.fills(2, LunchSlot.fruit), isTrue);
  });

  test('both callables are sent the treat days, Monday first', () {
    final packing = packingFor(every, treatDays: {5, 1, 3});
    final ideas = LunchIdeasRequest.toWire(
      householdId: 'h1',
      week: LunchFixtures.week,
      childIds: {lwazi},
      packing: packing,
      aisle: const [],
    );
    final week = LunchWeekRequest.toWire(
      householdId: 'h1',
      week: LunchFixtures.week,
      childIds: {lwazi},
      searches: const [],
      packing: packing,
    );
    for (final wire in [ideas, week]) {
      expect(wire['treatDays'], [1, 3, 5]);
      expect(wire['slots'], contains('treat'));
    }
    final none = LunchIdeasRequest.toWire(
      householdId: 'h1',
      week: LunchFixtures.week,
      childIds: {lwazi},
      packing: packingFor(every, treatDays: const {}),
      aisle: const [],
    );
    expect(none['treatDays'], isEmpty);
  });
}
