import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/fill_week_box.dart';
import 'package:nestprep/features/lunch_box/model/fill_week_preview.dart';
import 'package:nestprep/features/lunch_box/model/lunch_box.dart';
import 'package:nestprep/features/lunch_box/model/lunch_favourite.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/state/fill_week_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_recipe_repository.dart';
import '../../../support/fake_starter_boxes.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_harness.dart';

/// *Fill the week* step by step (lunch-box ADR-0020), on Tuesday 29
/// September — so Monday and Tuesday have gone: the boxes on offer in two
/// groups, the choice and its turns, the week before anything is written,
/// then one write that re-checks the board and makes ready-made items real
/// first. A ready-made list that cannot be read leaves the rest working.
void main() {
  const ayanda = LunchFixtures.ayandaId;
  const lwazi = LunchFixtures.lwaziId;
  late LunchHarness harness;
  late FakeLunchStarterBoxRepository starterBoxes;
  late FakeRecipeRepository recipes;
  late FillWeekController controller;

  final wrapDay = LunchFavourite.of(
    id: 'fav-wrap',
    childId: ayanda,
    name: 'Wrap day',
    box: LunchBox({
      LunchSlot.main: LunchPick.of(LunchFixtures.wrap),
      LunchSlot.fruit: LunchPick.of(LunchFixtures.grapes),
    }),
    createdBy: Fixtures.samMemberId,
  ).copyWith(createdAt: DateTime.utc(2026, 9, 2));
  final peanutDay = LunchFavourite.of(
    id: 'fav-pb',
    childId: lwazi,
    name: 'Peanut day',
    box: LunchBox({LunchSlot.main: LunchPick.of(LunchFixtures.peanutButter)}),
    createdBy: Fixtures.samMemberId,
  );

  FillWeekController open(String childId) {
    final made = FillWeekController(
      starterBoxes: starterBoxes,
      recipes: recipes,
      lunchRepository: harness.repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      childId: childId,
    );
    harness.controller.addListener(
      () => made.followBoard(harness.controller.board),
    );
    made.followBoard(harness.controller.board);
    return made;
  }

  setUp(() async {
    harness = LunchHarness();
    starterBoxes = FakeLunchStarterBoxRepository(StarterBoxFixtures.all);
    recipes = FakeRecipeRepository(StarterBoxFixtures.recipes);
    await harness.arrive(favourites: [wrapDay, peanutDay]);
    controller = open(ayanda);
    await pumpEventQueue();
  });

  tearDown(() async {
    controller.dispose();
    await harness.close();
  });

  FillWeekBox readyMade(String starterId) =>
      switch (controller.readyMadeBoxes) {
        AsyncData(:final value) => value.firstWhere(
          (box) => box.id == FillWeekBox.readyMadeId(starterId),
        ),
        _ => throw StateError('ready-made boxes not loaded'),
      };

  test('offers the child\'s own go-to boxes and NestPrep\'s, in two '
      'groups', () {
    expect(controller.step, FillWeekStep.boxes);
    expect(controller.goToBoxes.map((box) => box.name), ['Wrap day']);
    final offered = controller.readyMadeBoxes;
    expect(offered, isA<AsyncData<List<FillWeekBox>>>());
    expect(
      (offered as AsyncData<List<FillWeekBox>>).value.map((box) => box.name),
      ['The classic', 'Crunch time', 'Trail day'],
    );
  });

  test('nothing chosen, *Review the week* waits; chosen boxes take turns in '
      'the order they were chosen', () {
    controller.review();
    expect(controller.step, FillWeekStep.boxes);
    final crunch = readyMade('test-box-crunch');
    final mine = controller.goToBoxes.single;
    controller
      ..toggle(crunch)
      ..toggle(mine);
    expect(controller.turnOf(crunch), 1);
    expect(controller.turnOf(mine), 2);
    controller.review();
    expect(controller.step, FillWeekStep.review);
    final days = controller.preview!.days;
    expect(days.take(2).every((day) => day.hasGone), isTrue);
    String? boxOn(int index) => days[index].slots
        .map((slot) => slot.source)
        .whereType<FillWeekFromBox>()
        .firstOrNull
        ?.boxName;
    expect(
      [boxOn(2), boxOn(3), boxOn(4)],
      ['Crunch time', 'Wrap day', 'Crunch time'],
    );
  });

  test('back from the week keeps the choice; *Skip* clears it', () {
    final crunch = readyMade('test-box-crunch');
    controller
      ..toggle(crunch)
      ..review()
      ..back();
    expect(controller.step, FillWeekStep.boxes);
    expect(controller.turnOf(crunch), 1);
    controller.skip();
    expect(controller.step, FillWeekStep.review);
    expect(controller.chosenBoxes, isEmpty);
  });

  test('a go-to box that is not safe for the child cannot be chosen', () async {
    final forLwazi = open(lwazi);
    await pumpEventQueue();
    final peanut = forLwazi.goToBoxes.single;
    expect(peanut.canBeChosen, isFalse);
    forLwazi.toggle(peanut);
    expect(forLwazi.chosenBoxes, isEmpty);
    forLwazi.dispose();
  });

  test('the ready-made list failing says so on its own, and go-to boxes and '
      'skipping still work; a retry reads it again', () async {
    final failing = FakeLunchStarterBoxRepository(StarterBoxFixtures.all)
      ..failWith = const UnavailableFailure();
    starterBoxes = failing;
    final broken = open(ayanda);
    await pumpEventQueue();
    expect(broken.readyMadeBoxes, isA<AsyncFailure<List<FillWeekBox>>>());
    expect(broken.goToBoxes, hasLength(1));
    broken.toggle(broken.goToBoxes.single);
    broken.review();
    expect(broken.step, FillWeekStep.review);
    failing.failWith = null;
    await broken.readyMade.load();
    expect(broken.readyMadeBoxes, isA<AsyncData<List<FillWeekBox>>>());
    broken.dispose();
  });

  test('filling writes the open days only, one write for the child, with '
      'ready-made items made real first', () async {
    controller
      ..toggle(readyMade('test-box-classic'))
      ..review();
    await controller.fill();
    expect(controller.step, FillWeekStep.done);
    final write = harness.repository.writtenPicks.single;
    expect(write.childId, ayanda);
    expect(
      {for (final key in write.picks.keys) key.split('_').first},
      {'3', '4', '5'},
    );
    final seeded = {
      for (final batch in harness.repository.seeded)
        for (final item in batch) item.id,
    };
    expect(seeded, containsAll(['recipe-test-hummus-wrap', 'seed-apple']));
    expect(controller.written!.lunches, write.picks.length);
    expect(controller.written!.skipped, 0);
  });

  test('a compartment packed after the review is never written over', () async {
    controller.skip();
    harness.emit(
      favourites: [wrapDay, peanutDay],
      plans: [
        LunchFixtures.plan(
          ayanda,
          slots: {
            LunchFixtures.key(3, LunchSlot.main): LunchPick.of(
              LunchFixtures.peanutButter,
            ),
          },
        ),
      ],
    );
    await pumpEventQueue();
    await controller.fill();
    final write = harness.repository.writtenPicks.single;
    expect(write.picks, isNot(contains(LunchFixtures.key(3, LunchSlot.main))));
  });

  test('a write that fails stays on the week and says so', () async {
    controller.skip();
    harness.repository.failWritesWith = const UnavailableFailure();
    await controller.fill();
    expect(controller.step, FillWeekStep.review);
    expect(controller.failure, isA<UnavailableFailure>());
    controller.dismissFailure();
    expect(controller.failure, isNull);
  });

  test('a child the board does not have has no boxes and no week', () async {
    final nobody = open('m-nobody');
    await pumpEventQueue();
    expect(nobody.childWeek, isNull);
    expect(nobody.preview, isNull);
    await nobody.fill();
    expect(harness.repository.writtenPicks, isEmpty);
    nobody.dispose();
  });
}
