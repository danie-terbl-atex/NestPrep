import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_auto_fill.dart';
import 'package:nestprep/features/lunch_box/model/lunch_box.dart';
import 'package:nestprep/features/lunch_box/model/lunch_favourite.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_taste.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';

/// Filling a week (lunch-box ADR-0003): favourites first, rotated so each
/// comes round again; then the best suggestion per empty slot; never over
/// something a person packed; never anything unsafe.
void main() {
  final week = LunchFixtures.week;
  final ayanda = LunchFixtures.ayandaEntry;
  final lwazi = LunchFixtures.lwaziEntry;
  String key(int day, LunchSlot slot) => LunchPlan.slotKey(day, slot);

  LunchFavourite favourite(
    String id,
    String childId,
    Map<LunchSlot, LunchPick> picks, {
    int minute = 0,
  }) => LunchFavourite.of(
    id: id,
    childId: childId,
    name: id,
    box: LunchBox(picks),
    createdBy: Fixtures.samMemberId,
  ).copyWith(createdAt: DateTime.utc(2026, 9, 1, 8, minute));

  final friday = favourite('friday', LunchFixtures.ayandaId, {
    LunchSlot.main: LunchPick.of(LunchFixtures.wrap),
    LunchSlot.fruit: LunchPick.of(LunchFixtures.apple),
  });
  final classic = favourite('classic', LunchFixtures.ayandaId, {
    LunchSlot.main: LunchPick.of(LunchFixtures.cheese),
  }, minute: 1);

  LunchAutoFillResult fill({
    LunchPlan? plan,
    List<LunchFavourite> favourites = const [],
    LunchWeek? on,
    bool forLwazi = false,
  }) => LunchAutoFill.fill(
    plan:
        plan ??
        LunchFixtures.plan(
          forLwazi ? LunchFixtures.lwaziId : LunchFixtures.ayandaId,
          week: on ?? week,
        ),
    week: on ?? week,
    favourites: favourites,
    library: LunchFixtures.library,
    rules: forLwazi ? lwazi.foodRules : ayanda.foodRules,
    taste: LunchTaste.nothingYet,
  );

  test('fills every empty slot of an empty week, a treat on Friday only', () {
    final result = fill();
    for (var day = 1; day <= 5; day++) {
      for (final slot in [
        LunchSlot.main,
        LunchSlot.fruit,
        LunchSlot.veg,
        LunchSlot.snack,
      ]) {
        expect(result.picks, contains(key(day, slot)), reason: '$day $slot');
      }
      expect(
        result.picks.containsKey(key(day, LunchSlot.treat)),
        day == DateTime.friday,
      );
    }
    expect(result.dayCount, 5);
  });

  test('never replaces what somebody packed', () {
    final packed = LunchFixtures.plan(
      LunchFixtures.ayandaId,
      slots: {key(2, LunchSlot.main): LunchPick.of(LunchFixtures.wrap)},
    );
    final result = fill(plan: packed);
    expect(result.picks.containsKey(key(2, LunchSlot.main)), isFalse);
    expect(result.picks, contains(key(2, LunchSlot.fruit)));
  });

  test('never packs anything unsafe for the child', () {
    final result = fill(forLwazi: true);
    for (final pick in result.picks.values) {
      expect(pick.itemId, isNot(anyOf('pb', 'trail')));
    }
  });

  test('never packs a dislike', () {
    final result = fill();
    expect(
      result.picks.values.map((pick) => pick.itemId),
      isNot(contains('cheese')),
    );
  });

  test('varies the week rather than repeating one favourite item', () {
    final result = fill();
    final mains = [
      for (var day = 1; day <= 5; day++)
        result.picks[key(day, LunchSlot.main)]!.itemId,
    ];
    // Two mains are open to Ayanda (she dislikes the third), and two fruits:
    // each pair alternates rather than one filling the week.
    final fruits = [
      for (var day = 1; day <= 5; day++)
        result.picks[key(day, LunchSlot.fruit)]!.itemId,
    ];
    expect(mains.toSet(), {'wrap', 'pb'});
    expect(fruits.toSet(), {'grapes', 'apple'});
  });

  test('packs favourites into empty days first, each once', () {
    final result = fill(favourites: [friday, classic]);
    expect(result.favouriteDays, hasLength(2));
    final used = {
      for (final day in result.favouriteDays)
        result.picks[key(day, LunchSlot.main)]!.itemId,
    };
    expect(used, {'wrap', 'cheese'});
  });

  test('rotates so a favourite comes round again in a later week', () {
    final thisWeek = fill(favourites: [friday, classic]);
    final nextWeek = fill(favourites: [friday, classic], on: week.next);
    final mondayThis = thisWeek.picks[key(1, LunchSlot.main)]!.itemId;
    final mondayNext = nextWeek.picks[key(1, LunchSlot.main)]!.itemId;
    // Five places on each week: with two favourites, Monday alternates.
    expect({mondayThis, mondayNext}, {'wrap', 'cheese'});
  });

  test('rotation is the same list turned, never reshuffled', () {
    final three = [
      friday,
      classic,
      favourite('third', LunchFixtures.ayandaId, {
        LunchSlot.fruit: LunchPick.of(LunchFixtures.grapes),
      }, minute: 2),
    ];
    for (var offset = 0; offset < 6; offset++) {
      final order = LunchAutoFill.rotationFor(week.shift(offset), three);
      expect(order, hasLength(3));
      expect(order.toSet(), three.toSet());
      final start = three.indexOf(order.first);
      expect(order, [...three.skip(start), ...three.take(start)]);
    }
  });

  test('skips a favourite that is not safe for the child any more', () {
    final unsafe = favourite('unsafe', LunchFixtures.lwaziId, {
      LunchSlot.main: LunchPick.of(LunchFixtures.peanutButter),
    });
    final result = fill(favourites: [unsafe], forLwazi: true);
    expect(result.favouriteDays, isEmpty);
  });

  test('only uses the child’s own favourites', () {
    final result = fill(favourites: [friday], forLwazi: true);
    expect(result.favouriteDays, isEmpty);
  });

  test('is deterministic', () {
    expect(
      fill(favourites: [friday, classic]).picks,
      fill(favourites: [friday, classic]).picks,
    );
  });
}
