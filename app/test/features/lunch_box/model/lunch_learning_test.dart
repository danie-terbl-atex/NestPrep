import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_feedback.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_suggestion_reasons.dart';
import 'package:nestprep/features/lunch_box/model/lunch_suggestions.dart';
import 'package:nestprep/features/lunch_box/model/lunch_taste.dart';

import '../../../support/lunch_fixtures.dart';

/// The learning, exactly as lunch-box ADR-0003 writes it down: eaten boosts,
/// left demotes, an item's own mark counts for more than the box's, recent
/// weeks count in full, dislikes and unsafe items are never suggested.
void main() {
  final week = LunchFixtures.week;
  final apple = LunchPick.of(LunchFixtures.apple);
  final grapes = LunchPick.of(LunchFixtures.grapes);
  String key(int day) => LunchFixtures.key(day, LunchSlot.fruit);

  LunchTaste tasteFrom(
    Map<String, LunchPick> slots,
    Map<String, LunchFeedback> marks, {
    int weeksAgo = 0,
  }) => LunchTaste.from(
    history: [
      LunchFixtures.plan(
        LunchFixtures.ayandaId,
        week: week.shift(-weeksAgo),
        slots: slots,
        feedback: marks,
      ),
    ],
    current: week,
  );

  group('a mark', () {
    test('eaten with the box is +1, on its own +2', () {
      final withBox = tasteFrom(
        {key(1): apple},
        {'1': LunchFixtures.feedback(LunchVerdict.ate)},
      );
      final own = tasteFrom(
        {key(1): apple},
        {
          '1': LunchFixtures.feedback(
            LunchVerdict.left,
            items: {LunchSlot.fruit: LunchVerdict.ate},
          ),
        },
      );
      expect(withBox.of('apple').score, 1);
      expect(own.of('apple').score, 2);
      expect(own.of('apple').eaten, 1);
    });

    test('left with the box is −1, on its own −3', () {
      final withBox = tasteFrom(
        {key(1): apple},
        {'1': LunchFixtures.feedback(LunchVerdict.left)},
      );
      final own = tasteFrom(
        {key(1): apple},
        {
          '1': LunchFixtures.feedback(
            LunchVerdict.ate,
            items: {LunchSlot.fruit: LunchVerdict.left},
          ),
        },
      );
      expect(withBox.of('apple').score, -1);
      expect(own.of('apple').score, -3);
      expect(own.of('apple').left, 1);
    });

    test('counts in full for four weeks, at half for four more, then not', () {
      final marks = {'1': LunchFixtures.feedback(LunchVerdict.ate)};
      expect(
        tasteFrom({key(1): apple}, marks, weeksAgo: 3).of('apple').score,
        1,
      );
      expect(
        tasteFrom({key(1): apple}, marks, weeksAgo: 5).of('apple').score,
        0.5,
      );
      expect(
        tasteFrom({key(1): apple}, marks, weeksAgo: 9).of('apple'),
        ItemTaste.unknown,
      );
    });

    test('from a week that has not happened teaches nothing', () {
      final marks = {'1': LunchFixtures.feedback(LunchVerdict.ate)};
      expect(
        tasteFrom({key(1): apple}, marks, weeksAgo: -1).of('apple'),
        ItemTaste.unknown,
      );
    });

    test('an empty slot is not marked, whatever the box says', () {
      final taste = tasteFrom({}, {
        '1': LunchFixtures.feedback(LunchVerdict.ate),
      });
      expect(taste.isEmpty, isTrue);
    });
  });

  group('suggestions', () {
    final rules = LunchFixtures.ayandaEntry.foodRules;
    final library = LunchFixtures.library;

    List<String> ranked(
      LunchSlot slot,
      LunchTaste taste, {
      Map<String, int> uses = const {},
    }) => LunchSuggestions.rank(
      slot: slot,
      library: library,
      rules: rules,
      taste: taste,
      usesThisWeek: uses,
    ).suggested.map((entry) => entry.item.id).toList();

    test('with no history are liked first, then by name', () {
      // Ayanda likes grapes.
      expect(ranked(LunchSlot.fruit, LunchTaste.nothingYet), [
        'grapes',
        'apple',
      ]);
    });

    test('change after one box comes home — the next one is different', () {
      final before = ranked(LunchSlot.fruit, LunchTaste.nothingYet).first;
      final taste = tasteFrom(
        {key(1): grapes, key(2): apple},
        {
          '1': LunchFixtures.feedback(
            LunchVerdict.ate,
            items: {LunchSlot.fruit: LunchVerdict.left},
          ),
          '2': LunchFixtures.feedback(
            LunchVerdict.ate,
            items: {LunchSlot.fruit: LunchVerdict.ate},
          ),
        },
      );
      final after = ranked(LunchSlot.fruit, taste).first;
      expect(before, 'grapes');
      expect(after, 'apple');
    });

    test('lean away from what the week already holds', () {
      expect(
        ranked(LunchSlot.fruit, LunchTaste.nothingYet, uses: {'grapes': 1}),
        ['apple', 'grapes'],
      );
    });

    test('never offer what the child dislikes, but keep it to hand', () {
      final result = LunchSuggestions.rank(
        slot: LunchSlot.main,
        library: library,
        rules: rules,
        taste: LunchTaste.nothingYet,
      );
      expect(
        result.suggested.map((entry) => entry.item.id),
        isNot(contains('cheese')),
      );
      expect(result.disliked.single.item.id, 'cheese');
    });

    test('never offer what is unsafe, and say so', () {
      final result = LunchSuggestions.rank(
        slot: LunchSlot.main,
        library: library,
        rules: LunchFixtures.lwaziEntry.foodRules,
        taste: LunchTaste.nothingYet,
      );
      expect(result.unsafe.map((entry) => entry.item.id), ['pb']);
      expect(
        result.suggested.map((entry) => entry.item.id),
        isNot(contains('pb')),
      );
    });

    test('leave out what has been put away', () {
      final result = LunchSuggestions.rank(
        slot: LunchSlot.fruit,
        library: [
          LunchFixtures.apple,
          LunchFixtures.item(
            'old',
            'Old pear',
            LunchSlot.fruit,
            archived: true,
          ),
        ],
        rules: rules,
        taste: LunchTaste.nothingYet,
      );
      expect(result.suggested.map((entry) => entry.item.id), ['apple']);
    });

    test('carry the reasons they rank where they do', () {
      final taste = tasteFrom(
        {key(1): grapes},
        {'1': LunchFixtures.feedback(LunchVerdict.ate)},
      );
      final grapesEntry = LunchSuggestions.rank(
        slot: LunchSlot.fruit,
        library: library,
        rules: rules,
        taste: taste,
        usesThisWeek: {'grapes': 1},
      ).suggested.firstWhere((entry) => entry.item.id == 'grapes');
      final reasons = LunchSuggestionReasons.of(grapesEntry);
      expect(reasons.whereType<Liked>(), hasLength(1));
      expect(reasons.whereType<Eaten>().single.times, 1);
      expect(reasons.whereType<AlreadyThisWeek>().single.times, 1);
    });
  });
}
