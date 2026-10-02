import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_board.dart';
import 'package:nestprep/features/lunch_box/model/lunch_budget_reading.dart';
import 'package:nestprep/features/lunch_box/model/lunch_cheaper_swaps.dart';
import 'package:nestprep/features/lunch_box/model/lunch_cost.dart';
import 'package:nestprep/features/lunch_box/model/lunch_feedback.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_price.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week_cost.dart';
import 'package:nestprep/shared/money/money.dart';
import 'package:nestprep/shared/money/money_input.dart';

import '../../../support/lunch_fixtures.dart';

/// Budget mode's arithmetic (lunch-box ADR-0007): whole cents, rounded once
/// where they are shown; totals per box, child and week that say *at least*
/// when something has no price; a gentle meter; and cheaper swaps that stay
/// safe for the child and as well eaten.
void main() {
  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);

  LunchPrice price(String itemId, int cents, [int portions = 1]) => LunchPrice(
    id: itemId,
    cents: cents,
    portions: portions,
    updatedBy: 'm-sam',
  );

  LunchBoard boardOf(List<LunchPlan> plans) => LunchBoard.from(
    week: LunchFixtures.week,
    today: LunchFixtures.today,
    roster: LunchFixtures.roster(),
    library: LunchFixtures.library,
    favourites: const [],
    plans: plans,
  );

  group('money', () {
    test('a pack is shared to the thousandth of a cent, rounded once', () {
      // R10 across three boxes is 333.333… cents a box; three of them are
      // R10.00, not the R9.99 that rounding each box first would give.
      final share = LunchCost.share(cents: 1000, portions: 3);
      expect(share.money, const Money(333));
      expect((share * 3).money, const Money(1000));
    });

    test('is written for a person with a symbol and grouped rands', () {
      expect(const Money(1234567).display, 'R12 345.67');
      expect(const Money(25000).displayShort, 'R250');
      expect(const Money(2550).displayShort, 'R25.50');
      expect(const Money(-340).display, '-R3.40');
    });

    test('reads what somebody typed, and refuses what it cannot read', () {
      expect(MoneyInput.parse('12'), const Money(1200));
      expect(MoneyInput.parse('12.5'), const Money(1250));
      expect(MoneyInput.parse('R12,50'), const Money(1250));
      expect(MoneyInput.parse(' R 1 250 '), const Money(125000));
      for (final bad in ['12.505', 'abc', '-3', '', '1.2.3']) {
        expect(MoneyInput.parse(bad), isNull, reason: bad);
      }
      expect(MoneyInput.edit(const Money(1250)), '12.50');
    });
  });

  group('what the week costs', () {
    final plans = [
      LunchFixtures.plan(
        LunchFixtures.ayandaId,
        slots: {
          key(1, LunchSlot.main): LunchPick.of(LunchFixtures.wrap),
          key(1, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple),
          key(2, LunchSlot.main): LunchPick.of(LunchFixtures.wrap),
          key(2, LunchSlot.snack): LunchPick.of(LunchFixtures.biltong),
        },
      ),
    ];

    test('is the household basket: every child together, in whole packs', () {
      // Two wraps from a bag that does eight is one bag, R42 — not 2/8 of it.
      final cost = LunchWeekCost.of(
        board: boardOf(plans),
        prices: {
          'wrap': price('wrap', 4200, 8),
          'apple': price('apple', 450),
          'biltong': price('biltong', 1500),
        },
      );
      expect(cost.basket.lineFor('wrap')!.packs, 1);
      expect(cost.basket.lineFor('wrap')!.cost, const Money(4200));
      expect(cost.basket.total, const Money(6150));
      expect(cost.isAtLeast, isFalse);
    });

    test('a pack is bought again once its boxes run out, across children', () {
      final twoChildren = [
        ...plans,
        LunchFixtures.plan(
          LunchFixtures.lwaziId,
          slots: {
            for (var day = 1; day <= 5; day++)
              key(day, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple),
          },
        ),
      ];
      final cost = LunchWeekCost.of(
        board: boardOf(twoChildren),
        prices: {'apple': price('apple', 3000, 4)},
      );
      // Six apple boxes from bags of four: two bags.
      expect(cost.basket.lineFor('apple')!.boxes, 6);
      expect(cost.basket.lineFor('apple')!.packs, 2);
      expect(cost.basket.total, const Money(6000));
    });

    test('an unpriced thing makes the total *at least*, and is named', () {
      final cost = LunchWeekCost.of(
        board: boardOf(plans),
        prices: {'wrap': price('wrap', 4200, 8)},
      );
      expect(cost.isAtLeast, isTrue);
      expect(
        cost.unpricedNames.values,
        containsAll(['Apple slices', 'Biltong']),
      );
    });
  });

  group('the meter', () {
    LunchBudgetBand band(int spent, int budget) =>
        LunchBudgetReading(spent: Money(spent), budget: Money(budget)).band;

    test('is calm under 90%, nearly there to 100%, over past it', () {
      expect(band(8999, 10000), LunchBudgetBand.calm);
      expect(band(9000, 10000), LunchBudgetBand.nearly);
      expect(band(10000, 10000), LunchBudgetBand.nearly);
      expect(band(10001, 10000), LunchBudgetBand.over);
    });

    test('says how much is left, or how far over', () {
      const over = LunchBudgetReading(
        spent: Money(13800),
        budget: Money(10000),
      );
      expect(over.difference, const Money(3800));
      expect(over.fraction, 1);
    });
  });

  group('cheaper swaps', () {
    final dearWeek = [
      LunchFixtures.plan(
        LunchFixtures.ayandaId,
        slots: {
          // Monday is gone; Tuesday and Wednesday are still to come.
          key(1, LunchSlot.fruit): LunchPick.of(LunchFixtures.grapes),
          key(2, LunchSlot.fruit): LunchPick.of(LunchFixtures.grapes),
          key(3, LunchSlot.fruit): LunchPick.of(LunchFixtures.grapes),
        },
      ),
    ];

    List<LunchCheaperSwap> swapsFor(
      String childId,
      List<LunchPlan> plans,
      Map<String, LunchPrice> prices,
    ) {
      final board = boardOf(plans);
      return LunchCheaperSwaps.find(
        board: board,
        childWeek: board.childWeek(childId)!,
        prices: prices,
      );
    }

    test('offers the cheaper thing for the same slot, on the days to come', () {
      final swaps = swapsFor(LunchFixtures.ayandaId, dearWeek, {
        'grapes': price('grapes', 1200),
        'apple': price('apple', 450),
      });
      final swap = swaps.single;
      expect(swap.from.id, 'grapes');
      expect(swap.to.item.id, 'apple');
      expect(swap.weekdays, [2, 3]);
      expect(swap.saving.money, const Money(1500));
    });

    test('offers nothing dearer, unpriced, or less well eaten', () {
      expect(
        swapsFor(LunchFixtures.ayandaId, dearWeek, {
          'grapes': price('grapes', 400),
          'apple': price('apple', 450),
        }),
        isEmpty,
      );
      expect(
        swapsFor(LunchFixtures.ayandaId, dearWeek, {
          'grapes': price('grapes', 1200),
        }),
        isEmpty,
      );
      // Apples came home twice, marked on their own: well below grapes.
      final leftApples = [
        for (final week in [1, 2])
          LunchFixtures.plan(
            LunchFixtures.ayandaId,
            week: LunchFixtures.week.shift(-week),
            slots: {key(1, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple)},
            feedback: {
              '1': LunchFixtures.feedback(
                LunchVerdict.ate,
                items: {LunchSlot.fruit: LunchVerdict.left},
              ),
            },
          ),
      ];
      expect(
        swapsFor(
          LunchFixtures.ayandaId,
          [...dearWeek, ...leftApples],
          {'grapes': price('grapes', 1200), 'apple': price('apple', 450)},
        ),
        isEmpty,
      );
    });

    test('never offers what is unsafe for the child, however cheap', () {
      final lwaziWeek = [
        LunchFixtures.plan(
          LunchFixtures.lwaziId,
          slots: {key(3, LunchSlot.main): LunchPick.of(LunchFixtures.wrap)},
        ),
      ];
      final swaps = swapsFor(LunchFixtures.lwaziId, lwaziWeek, {
        'wrap': price('wrap', 3000),
        'pb': price('pb', 100),
        'cheese': price('cheese', 900),
      });
      expect(swaps.single.to.item.id, 'cheese');
    });
  });
}
