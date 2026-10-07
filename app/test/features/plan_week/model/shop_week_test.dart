import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/food_rules.dart';
import 'package:nestprep/features/lunch_box/model/lunch_board.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/model/checked_product.dart';
import 'package:nestprep/features/plan_week/model/idea_search.dart';
import 'package:nestprep/features/plan_week/model/lunch_idea.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';
import 'package:nestprep/features/plan_week/model/plan_fallback.dart';
import 'package:nestprep/features/plan_week/model/shop_week_assembly.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/checkers_fakes_for_plan_week.dart';
import '../../../support/lunch_fixtures.dart';

/// The week built from the shop's products (lunch-box ADR-0012, step 4):
/// the model's answer checked again on the phone, a week made without AI
/// from the same products, and the basket in whole packs.
void main() {
  const lwazi = LunchFixtures.lwaziId;
  const ayanda = LunchFixtures.ayandaId;
  String key(int day, LunchSlot slot) => LunchPlan.slotKey(day, slot);
  final every = {...LunchSlot.values};
  final rules = <String, FoodRules>{
    lwazi: LunchFixtures.lwaziEntry.foodRules,
    ayanda: LunchFixtures.ayandaEntry.foodRules,
  };

  LunchBoard board({Map<String, LunchPick> lwaziSlots = const {}}) =>
      LunchBoard.from(
        week: LunchFixtures.week,
        today: LunchFixtures.today,
        roster: LunchFixtures.roster(),
        library: LunchFixtures.library,
        favourites: const [],
        plans: [LunchFixtures.plan(lwazi, slots: lwaziSlots)],
      );

  IdeaSearch searched(String id, LunchSlot slot, List<CheckedProduct> found) =>
      IdeaSearch(
        idea: LunchIdea.checked(
          id: id,
          slot: slot,
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
  final apples = CheckedProduct.of(
    planWeekProduct('Apples 1kg bag', id: 'apples', cents: 2999),
    rules,
  );
  final cheapApples = CheckedProduct.of(
    planWeekProduct(
      'Apples 6 pack',
      id: 'apples6',
      cents: 2400,
      packCount: 6,
      ingredients: 'Apples',
    ),
    rules,
  );
  final searches = [
    searched('snacks', LunchSlot.snack, [yoghurt, rusks]),
    searched('fruit', LunchSlot.fruit, [apples, cheapApples]),
  ];

  ReplyLunch lunch(
    String child,
    int day,
    LunchSlot slot,
    String idea,
    String product,
  ) => ReplyLunch(
    childId: child,
    day: day,
    slot: slot,
    ideaId: idea,
    productId: product,
  );

  group('from the model', () {
    test('keeps what fits and drops what does not, on the phone too', () {
      final week = ShopWeekAssembly.fromReply(
        board: board(
          lwaziSlots: {
            key(1, LunchSlot.snack): LunchPick.of(LunchFixtures.biltong),
          },
        ),
        childIds: {lwazi, ayanda},
        searches: searches,
        budget: const Money(10000),
        slots: every,
        reply: LunchWeekReply(
          lunches: [
            lunch(ayanda, 1, LunchSlot.snack, 'snacks', 'yog'),
            // Already packed by a person.
            lunch(lwazi, 1, LunchSlot.snack, 'snacks', 'rusk'),
            // The product is in another idea's slot.
            lunch(ayanda, 2, LunchSlot.fruit, 'snacks', 'yog'),
            // Rice cakes were never found for this idea.
            lunch(ayanda, 3, LunchSlot.snack, 'snacks', 'rice'),
            // The second answer for one compartment.
            lunch(ayanda, 1, LunchSlot.snack, 'snacks', 'rusk'),
            lunch(lwazi, 2, LunchSlot.fruit, 'fruit', 'apples6'),
          ],
          boxesPerPack: const {'yog': 6},
          budgetCents: null,
          dropped: 1,
          callsLeft: 41,
        ),
      );
      expect(week.source, PlanSource.ai);
      final ayandaWeek = week.children.firstWhere((c) => c.childId == ayanda);
      final lwaziWeek = week.children.firstWhere((c) => c.childId == lwazi);
      expect(ayandaWeek.added.keys, [key(1, LunchSlot.snack)]);
      expect(ayandaWeek.added.values.single.productId, 'yog');
      expect(lwaziWeek.added.keys, [key(2, LunchSlot.fruit)]);
      expect(week.boxesPerPackOf('yog'), 6);
      // The shop said six to a pack; the model said nothing about apples.
      expect(week.boxesPerPackOf('apples6'), 6);
      expect(week.dropped, 1);
      expect(week.callsLeft, 41);
    });
  });

  group('without AI', () {
    test('fills every empty compartment from the cheapest product a box, and '
        'leaves what a person packed', () {
      final week = ShopWeekAssembly.fallback(
        board: board(
          lwaziSlots: {
            key(1, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple),
          },
        ),
        childIds: {lwazi},
        searches: searches,
        budget: null,
        slots: every,
        reason: PlanFallbackReason.aiLimitReached,
      );
      final lwaziWeek = week.children.single;
      expect(week.source, PlanSource.fallback);
      expect(week.fallbackReason, PlanFallbackReason.aiLimitReached);
      expect(lwaziWeek.added.containsKey(key(1, LunchSlot.fruit)), isFalse);
      expect([
        for (var day = 2; day <= 5; day++)
          lwaziWeek.addedAt(day, LunchSlot.fruit)?.productId,
      ], everyElement('apples6'));
      expect(lwaziWeek.added.containsKey(key(1, LunchSlot.snack)), isTrue);
      expect(lwaziWeek.addedAt(1, LunchSlot.main), isNull);
    });

    test('gives children who may have the same things the same box each '
        'day, so it is packed once', () {
      final week = ShopWeekAssembly.fallback(
        board: board(),
        childIds: {lwazi, ayanda},
        searches: [
          searched('yoghurts', LunchSlot.snack, [yoghurt]),
          searched('rusks', LunchSlot.snack, [rusks]),
        ],
        budget: null,
        slots: {LunchSlot.snack},
        reason: PlanFallbackReason.offline,
      );
      List<String?> snacksOf(String childId) => [
        for (var day = 1; day <= 5; day++)
          week.children
              .singleWhere((child) => child.childId == childId)
              .addedAt(day, LunchSlot.snack)
              ?.productId,
      ];
      expect(snacksOf(lwazi), everyElement(isNotNull));
      expect(snacksOf(ayanda), snacksOf(lwazi));
      expect(snacksOf(lwazi).toSet(), {'yog', 'rusk'});
    });
  });

  test('fills only the compartments the brief fills, by the model or '
      'not', () {
    final fallback = ShopWeekAssembly.fallback(
      board: board(),
      childIds: {lwazi, ayanda},
      searches: searches,
      budget: null,
      slots: {LunchSlot.snack},
      reason: PlanFallbackReason.offline,
    );
    for (final child in fallback.children) {
      expect(
        child.added.keys.every((k) => k.endsWith(LunchSlot.snack.name)),
        isTrue,
      );
    }
    expect(fallback.children.first.added, isNotEmpty);
    expect(fallback.slots, {LunchSlot.snack});

    final fromModel = ShopWeekAssembly.fromReply(
      board: board(),
      childIds: {lwazi, ayanda},
      searches: searches,
      budget: null,
      slots: {LunchSlot.snack},
      reply: LunchWeekReply(
        lunches: [
          lunch(ayanda, 1, LunchSlot.snack, 'snacks', 'yog'),
          lunch(lwazi, 2, LunchSlot.fruit, 'fruit', 'apples6'),
        ],
        boxesPerPack: const {},
        budgetCents: null,
        dropped: 0,
        callsLeft: null,
      ),
    );
    expect(fromModel.pickCount, 1);
  });

  group('the basket', () {
    test('is whole packs across every child', () {
      var week = ShopWeekAssembly.fallback(
        board: board(),
        childIds: {lwazi, ayanda},
        searches: [searches[1]],
        budget: const Money(5000),
        slots: every,
        reason: PlanFallbackReason.offline,
      );
      // Ten fruit boxes, six apples a pack: two packs of R24.
      expect(week.basket.lineFor('apples6')!.boxes, 10);
      expect(week.basket.total, const Money(4800));
      week = week.withPick(ayanda, key(1, LunchSlot.fruit), null);
      expect(week.basket.lineFor('apples6')!.boxes, 9);
    });

    test('offers a swap only from what was kept for that child', () {
      final week = ShopWeekAssembly.fallback(
        board: board(),
        childIds: {lwazi, ayanda},
        searches: searches,
        budget: null,
        slots: every,
        reason: PlanFallbackReason.offline,
      );
      // The 1kg bag says nothing about what is in it; Lwazi has allergies.
      final forLwazi = week.optionsFor(lwazi, LunchSlot.fruit);
      final forAyanda = week.optionsFor(ayanda, LunchSlot.fruit);
      expect([for (final (_, p) in forLwazi) p.productId], ['apples6']);
      expect(
        [for (final (_, p) in forAyanda) p.productId],
        ['apples', 'apples6'],
      );
    });
  });
}
