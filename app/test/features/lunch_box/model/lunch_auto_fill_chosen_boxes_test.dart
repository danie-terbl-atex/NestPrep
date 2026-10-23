import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/family_entry.dart';
import 'package:nestprep/features/lunch_box/model/fill_week_box.dart';
import 'package:nestprep/features/lunch_box/model/lunch_auto_fill.dart';
import 'package:nestprep/features/lunch_box/model/lunch_box.dart';
import 'package:nestprep/features/lunch_box/model/lunch_favourite.dart';
import 'package:nestprep/features/lunch_box/model/lunch_fill_choice.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_starter_box.dart';
import 'package:nestprep/features/lunch_box/model/lunch_taste.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_starter_boxes.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';

/// *Fill the week*'s fill (lunch-box ADR-0020), through ADR-0003's one
/// filler: the boxes a parent chose take turns over the open, empty school
/// days; a day that has gone is never filled; NestPrep fills the rest —
/// an unsafe ready-made compartment included — with treats on Friday only;
/// nothing a person packed is touched; and skipping is ADR-0003's fill.
void main() {
  final week = LunchFixtures.week;
  final saturdayBefore = week.monday.addDays(-2);
  final wednesday = week.monday.addDays(2);
  String key(int day, LunchSlot slot) => LunchPlan.slotKey(day, slot);

  FillWeekBox readyMade(LunchStarterBox box, FamilyEntry child) =>
      FillWeekBox.readyMade(
        box,
        recipes: {
          for (final recipe in StarterBoxFixtures.recipes) recipe.id: recipe,
        },
        rules: child.foodRules,
        library: {for (final item in LunchFixtures.library) item.id: item},
        addedBy: Fixtures.samMemberId,
      );

  final favourite = LunchFavourite.of(
    id: 'fav-wrap',
    childId: LunchFixtures.ayandaId,
    name: 'Wrap day',
    box: LunchBox({
      LunchSlot.main: LunchPick.of(LunchFixtures.wrap),
      LunchSlot.fruit: LunchPick.of(LunchFixtures.grapes),
    }),
    createdBy: Fixtures.samMemberId,
  ).copyWith(createdAt: DateTime.utc(2026, 9, 2));

  LunchAutoFillResult fill({
    FamilyEntry? child,
    LunchPlan? plan,
    List<FillWeekBox> boxes = const [],
    List<LunchFavourite> favourites = const [],
    CalendarDate? today,
    bool asked = true,
  }) {
    final entry = child ?? LunchFixtures.ayandaEntry;
    return LunchAutoFill.fill(
      plan: plan ?? LunchFixtures.plan(entry.memberId),
      week: week,
      favourites: favourites,
      library: LunchFixtures.library,
      rules: entry.foodRules,
      taste: LunchTaste.nothingYet,
      choice: asked
          ? LunchFillChoice(today: today ?? saturdayBefore, boxes: boxes)
          : null,
    );
  }

  test('two chosen boxes take turns: Monday the first, Tuesday the second, '
      'Wednesday the first again', () {
    final ayanda = LunchFixtures.ayandaEntry;
    final result = fill(
      boxes: [
        readyMade(StarterBoxFixtures.classic, ayanda),
        readyMade(StarterBoxFixtures.crunch, ayanda),
      ],
    );
    expect(
      [
        for (var day = 1; day <= 5; day++)
          result.packedFromBox[key(day, LunchSlot.main)],
      ],
      [
        'The classic',
        'Crunch time',
        'The classic',
        'Crunch time',
        'The classic',
      ],
    );
    expect(result.picks[key(2, LunchSlot.main)]!.itemId, 'seed-cheese-rolls');
  });

  test('a school day that has gone is never filled — on a Wednesday the box '
      'starts on Thursday (lunch-box ADR-0019, ADR-0020)', () {
    final ayanda = LunchFixtures.ayandaEntry;
    final result = fill(
      today: wednesday,
      boxes: [
        readyMade(StarterBoxFixtures.classic, ayanda),
        readyMade(StarterBoxFixtures.crunch, ayanda),
      ],
    );
    final days = {for (final k in result.picks.keys) k.split('_').first};
    expect(days, {'4', '5'});
    expect(result.packedFromBox[key(4, LunchSlot.main)], 'The classic');
    expect(result.packedFromBox[key(5, LunchSlot.main)], 'Crunch time');
  });

  test('a ready-made compartment that is not safe for the child is filled '
      'by NestPrep with a safe suggestion', () {
    final lwazi = LunchFixtures.lwaziEntry;
    final result = fill(
      child: lwazi,
      boxes: [readyMade(StarterBoxFixtures.trail, lwazi)],
    );
    final snack = result.picks[key(1, LunchSlot.snack)]!;
    expect(snack.itemId, isNot('seed-trail-mix'));
    expect(snack.itemId, 'biltong');
    expect(result.packedFromBox, isNot(contains(key(1, LunchSlot.snack))));
  });

  test('nothing a person packed is touched, and a part-packed day is not a '
      'box day — the box goes on the next empty one', () {
    final ayanda = LunchFixtures.ayandaEntry;
    final packed = LunchFixtures.plan(
      LunchFixtures.ayandaId,
      slots: {key(1, LunchSlot.main): LunchPick.of(LunchFixtures.wrap)},
    );
    final result = fill(
      plan: packed,
      boxes: [readyMade(StarterBoxFixtures.crunch, ayanda)],
    );
    expect(result.picks, isNot(contains(key(1, LunchSlot.main))));
    expect(result.picks, contains(key(1, LunchSlot.fruit)));
    expect(result.packedFromBox, isNot(contains(key(1, LunchSlot.fruit))));
    expect(result.packedFromBox[key(2, LunchSlot.main)], 'Crunch time');
  });

  test('a treat goes in on Friday only, from the box or from NestPrep', () {
    final ayanda = LunchFixtures.ayandaEntry;
    final result = fill(boxes: [readyMade(StarterBoxFixtures.classic, ayanda)]);
    for (var day = 1; day <= 4; day++) {
      expect(result.picks, isNot(contains(key(day, LunchSlot.treat))));
    }
    expect(
      result.picks[key(5, LunchSlot.treat)]!.itemId,
      'recipe-test-oat-muffin',
    );
  });

  test('with boxes chosen, the go-to boxes nobody chose stay out', () {
    final ayanda = LunchFixtures.ayandaEntry;
    final result = fill(
      favourites: [favourite],
      boxes: [readyMade(StarterBoxFixtures.crunch, ayanda)],
    );
    expect(result.favouriteDays, isEmpty);
    expect(result.packedFromBox.values.toSet(), {'Crunch time'});
  });

  test('a chosen go-to box takes its turn like any other', () {
    final ayanda = LunchFixtures.ayandaEntry;
    final mine = FillWeekBox.goTo(
      favourite,
      rules: ayanda.foodRules,
      library: {for (final item in LunchFixtures.library) item.id: item},
    );
    final result = fill(
      boxes: [mine, readyMade(StarterBoxFixtures.crunch, ayanda)],
    );
    expect(result.packedFromBox[key(1, LunchSlot.main)], 'Wrap day');
    expect(result.packedFromBox[key(2, LunchSlot.main)], 'Crunch time');
  });

  test('skipping is ADR-0003\'s fill: go-to boxes rotate first, then the '
      'best suggestion — the same week as without the flow', () {
    final skipped = fill(favourites: [favourite]);
    final before = fill(favourites: [favourite], asked: false);
    expect(skipped.picks, before.picks);
    expect(skipped.favouriteDays, before.favouriteDays);
    expect(skipped.favouriteDays, hasLength(1));
    expect(skipped.packedFromBox.values.toSet(), {'Wrap day'});
  });

  test('skipping still leaves the days that have gone', () {
    final skipped = fill(favourites: [favourite], today: wednesday);
    expect(skipped.favouriteDays, [4]);
    final days = {for (final k in skipped.picks.keys) k.split('_').first};
    expect(days, {'4', '5'});
  });
}
