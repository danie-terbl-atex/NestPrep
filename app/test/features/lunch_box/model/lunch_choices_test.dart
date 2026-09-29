import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_board.dart';
import 'package:nestprep/features/lunch_box/model/lunch_choice_day.dart';
import 'package:nestprep/features/lunch_box/model/lunch_choice_suggestions.dart';
import 'package:nestprep/features/lunch_box/model/lunch_choices.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';

import '../../../support/lunch_fixtures.dart';

/// Kid picks (lunch-box ADR-0008): what a child is offered — only days from
/// today, only compartments with options — and *Suggest options*, which
/// offers only what is safe and not disliked, two or three at a time.
void main() {
  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);

  LunchChoices choicesOf(
    String childId,
    Map<String, List<LunchPick>> options, {
    Map<String, String> chosen = const {},
  }) => LunchChoices.none(
    childId: childId,
    week: LunchFixtures.week,
  ).copyWith(options: options, chosen: chosen);

  LunchBoard boardOf(List<LunchPlan> plans) => LunchBoard.from(
    week: LunchFixtures.week,
    today: LunchFixtures.today,
    roster: LunchFixtures.roster(),
    library: LunchFixtures.library,
    favourites: const [],
    plans: plans,
  );

  final apple = LunchPick.of(LunchFixtures.apple);
  final grapes = LunchPick.of(LunchFixtures.grapes);

  group('the days a child chooses for', () {
    test(
      'are today and after, with only the compartments that have options',
      () {
        final choices = choicesOf(LunchFixtures.ayandaId, {
          key(1, LunchSlot.fruit): [apple, grapes],
          key(2, LunchSlot.fruit): [apple, grapes],
          key(4, LunchSlot.fruit): [apple, grapes],
        });
        final days = LunchChoiceDay.ahead(
          choices: choices,
          plan: LunchFixtures.plan(LunchFixtures.ayandaId),
          week: LunchFixtures.week,
          today: LunchFixtures.today,
        );
        expect(days.map((day) => day.date.weekday), [2, 4]);
        expect(days.first.slots.map((slot) => slot.slot), [LunchSlot.fruit]);
      },
    );

    test('a compartment is chosen when the box holds one of its options', () {
      final choices = choicesOf(LunchFixtures.ayandaId, {
        key(2, LunchSlot.fruit): [apple, grapes],
        key(2, LunchSlot.main): [
          LunchPick.of(LunchFixtures.wrap),
          LunchPick.of(LunchFixtures.cheese),
        ],
      });
      final plan = LunchFixtures.plan(
        LunchFixtures.ayandaId,
        slots: {
          key(2, LunchSlot.fruit): grapes,
          key(2, LunchSlot.main): LunchPick.of(LunchFixtures.peanutButter),
        },
      );
      final day = LunchChoiceDay.ahead(
        choices: choices,
        plan: plan,
        week: LunchFixtures.week,
        today: LunchFixtures.today,
      ).single;
      expect(day.chosenCount, 1);
      expect(day.isComplete, isFalse);
      expect(
        day.slots.firstWhere((s) => s.slot == LunchSlot.fruit).chosen?.itemId,
        'grapes',
      );
    });
  });

  group('suggest options', () {
    test('offers the child’s safe, liked-or-neutral top three, never the '
        'unsafe', () {
      final board = boardOf(const []);
      final lwazi = board.childWeek(LunchFixtures.lwaziId)!;
      final byDay = LunchChoiceSuggestions.forWeek(
        board: board,
        childWeek: lwazi,
        choices: choicesOf(LunchFixtures.lwaziId, const {}),
        today: LunchFixtures.today,
      );
      expect(byDay.keys, [2, 3, 4, 5]);
      final offered = [
        for (final day in byDay.values)
          for (final options in day.values) ...options,
      ];
      expect(offered.map((pick) => pick.itemId), isNot(contains('pb')));
      expect(offered.map((pick) => pick.itemId), isNot(contains('trail')));
      for (final day in byDay.values) {
        for (final options in day.values) {
          expect(options.length, inInclusiveRange(2, 3));
        }
      }
    });

    test('skips a compartment with one thing to offer, packed ones, and '
        'treats before Friday', () {
      final board = boardOf([
        LunchFixtures.plan(
          LunchFixtures.ayandaId,
          slots: {key(3, LunchSlot.main): LunchPick.of(LunchFixtures.wrap)},
        ),
      ]);
      final ayanda = board.childWeek(LunchFixtures.ayandaId)!;
      final byDay = LunchChoiceSuggestions.forWeek(
        board: board,
        childWeek: ayanda,
        choices: choicesOf(LunchFixtures.ayandaId, const {}),
        today: LunchFixtures.today,
      );
      // One veg and one treat in the library: never a choice of one.
      expect(byDay[2]!.keys, isNot(contains(key(2, LunchSlot.veg))));
      expect(byDay[2]!.keys, isNot(contains(key(2, LunchSlot.treat))));
      expect(byDay[3]!.keys, isNot(contains(key(3, LunchSlot.main))));
      expect(byDay[2]!.keys, contains(key(2, LunchSlot.fruit)));
    });

    test('leaves alone a compartment that already has options', () {
      final board = boardOf(const []);
      final ayanda = board.childWeek(LunchFixtures.ayandaId)!;
      final byDay = LunchChoiceSuggestions.forWeek(
        board: board,
        childWeek: ayanda,
        choices: choicesOf(LunchFixtures.ayandaId, {
          key(2, LunchSlot.fruit): [apple, grapes],
        }),
        today: LunchFixtures.today,
      );
      expect(byDay[2]!.keys, isNot(contains(key(2, LunchSlot.fruit))));
    });
  });
}
