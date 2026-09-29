import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_board.dart';
import 'package:nestprep/features/lunch_box/model/lunch_box.dart';
import 'package:nestprep/features/lunch_box/model/lunch_favourite.dart';
import 'package:nestprep/features/lunch_box/model/lunch_feedback.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item_draft.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_prep_list.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_harness.dart';

void main() {
  late LunchHarness harness;

  setUp(() => harness = LunchHarness());
  tearDown(() => harness.close());

  LunchBoard board() =>
      (harness.controller.board as AsyncData<LunchBoard>).value;
  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);

  group('reading', () {
    test(
      'holds loading until the children and every read have answered',
      () async {
        expect(harness.controller.board, isA<AsyncLoading<LunchBoard>>());
        harness.repository.emitItems(LunchFixtures.library);
        await pumpEventQueue();
        expect(harness.controller.board, isA<AsyncLoading<LunchBoard>>());
        await harness.arrive();
        expect(harness.controller.board, isA<AsyncData<LunchBoard>>());
      },
    );

    test('plans only for the children, each against their own rules', () async {
      await harness.arrive();
      expect(board().children.map((child) => child.childId), {
        LunchFixtures.lwaziId,
        LunchFixtures.ayandaId,
      });
      expect(
        board().childWeek(LunchFixtures.lwaziId)!.child.foodRules.isNutFree,
        isTrue,
      );
    });

    test('opens the week being planned, and the eight before it', () async {
      expect(harness.controller.week.key, '2026-W40');
      expect(harness.repository.watchedWindows.single, (
        from: '2026-W32',
        to: '2026-W40',
      ));
    });

    test('moving a week reopens only the window, and back again', () async {
      await harness.arrive();
      harness.controller.goToNextWeek();
      expect(harness.controller.board, isA<AsyncLoading<LunchBoard>>());
      await pumpEventQueue();
      expect(harness.repository.watchedWindows.last.to, '2026-W41');
      harness.controller.goToThisWeek();
      expect(harness.controller.week, LunchFixtures.week);
    });

    test('says a read failure in the board, with nothing written', () async {
      harness.repository.failItemsWith(const UnavailableFailure());
      await pumpEventQueue();
      expect(harness.controller.board, isA<AsyncFailure<LunchBoard>>());
    });

    test('says a family read failure too', () async {
      harness.controller.followRoster(
        const AsyncFailure(PermissionDeniedFailure()),
      );
      await pumpEventQueue();
      expect(harness.controller.board, isA<AsyncFailure<LunchBoard>>());
    });

    test('flags a box that has stopped being safe', () async {
      // Packed before Lwazi's peanut allergy mattered to anybody.
      await harness.arrive(
        plans: [
          LunchFixtures.plan(
            LunchFixtures.lwaziId,
            slots: {
              key(1, LunchSlot.main): LunchPick.of(LunchFixtures.peanutButter),
            },
          ),
        ],
      );
      final lwazi = board().childWeek(LunchFixtures.lwaziId)!;
      expect(lwazi.unsafeCount, 1);
      expect(lwazi.dayOn(1)!.isUnsafeAt(LunchSlot.main), isTrue);
    });
  });

  group('the starter library', () {
    test('is written once, the first time an editor finds none', () async {
      await harness.arrive(items: const []);
      harness.repository.emitItems(const []);
      await pumpEventQueue();
      expect(harness.repository.seeded, hasLength(1));
      expect(harness.repository.seeded.single, isNotEmpty);
      expect(
        harness.repository.seeded.single.every(
          (item) => item.addedBy == Fixtures.samMemberId,
        ),
        isTrue,
      );
    });

    test('is never written by somebody who may only look', () async {
      final viewer = LunchHarness(canEdit: false);
      addTearDown(viewer.close);
      await viewer.arrive(items: const []);
      expect(viewer.repository.seeded, isEmpty);
    });

    test('is not written over a library that exists', () async {
      await harness.arrive();
      expect(harness.repository.seeded, isEmpty);
    });
  });

  group('packing', () {
    test('two children, two different weeks', () async {
      await harness.arrive();
      await harness.controller.edit.pick(
        childId: LunchFixtures.lwaziId,
        isoWeekday: 1,
        item: LunchFixtures.wrap,
      );
      await harness.controller.edit.pick(
        childId: LunchFixtures.ayandaId,
        isoWeekday: 1,
        item: LunchFixtures.peanutButter,
      );
      final writes = harness.repository.writtenPicks;
      expect(writes.map((write) => write.childId), [
        LunchFixtures.lwaziId,
        LunchFixtures.ayandaId,
      ]);
      expect(writes.first.picks[key(1, LunchSlot.main)]!.itemId, 'wrap');
      expect(writes.last.picks[key(1, LunchSlot.main)]!.itemId, 'pb');
      expect(writes.first.week, '2026-W40');
    });

    test(
      'refuses an allergen before anything is written, and says why',
      () async {
        await harness.arrive();
        await harness.controller.edit.pick(
          childId: LunchFixtures.lwaziId,
          isoWeekday: 2,
          item: LunchFixtures.peanutButter,
        );
        expect(harness.repository.writtenPicks, isEmpty);
        expect(
          (harness.controller.actionFailure as LunchFailure?)?.problem,
          LunchProblem.unsafeForChild,
        );
      },
    );

    test('refuses tree nuts for a child at a nut-free school', () async {
      await harness.arrive();
      await harness.controller.edit.pick(
        childId: LunchFixtures.lwaziId,
        isoWeekday: 2,
        item: LunchFixtures.trailMix,
      );
      expect(harness.repository.writtenPicks, isEmpty);
    });

    test(
      'says a rules refusal as the child’s rules, not as permissions',
      () async {
        await harness.arrive();
        harness.repository.failWritesWith = const PermissionDeniedFailure();
        await harness.controller.edit.pick(
          childId: LunchFixtures.ayandaId,
          isoWeekday: 2,
          item: LunchFixtures.wrap,
        );
        expect(
          (harness.controller.actionFailure as LunchFailure?)?.problem,
          LunchProblem.refusedByRules,
        );
      },
    );

    test('adds something new to the library, then packs it', () async {
      await harness.arrive();
      await harness.controller.edit.addAndPick(
        childId: LunchFixtures.ayandaId,
        isoWeekday: 3,
        draft: const LunchItemDraft(
          name: 'Vetkoek',
          slot: LunchSlot.main,
          allergens: {},
        ),
      );
      expect(harness.repository.addedItems.single.name, 'Vetkoek');
      expect(
        harness
            .repository
            .writtenPicks
            .single
            .picks[key(3, LunchSlot.main)]!
            .itemId,
        'item-1',
      );
    });

    test('clears one slot, or a whole day', () async {
      await harness.arrive();
      await harness.controller.edit.clear(
        childId: LunchFixtures.ayandaId,
        isoWeekday: 1,
        slot: LunchSlot.veg,
      );
      await harness.controller.edit.clearDay(
        childId: LunchFixtures.ayandaId,
        isoWeekday: 2,
      );
      final writes = harness.repository.writtenPicks;
      expect(writes.first.picks, {key(1, LunchSlot.veg): null});
      expect(writes.last.picks.keys, hasLength(5));
      expect(writes.last.picks.values.every((pick) => pick == null), isTrue);
    });

    test('fills the week in one write, and says what it did', () async {
      await harness.arrive();
      await harness.controller.edit.autoFill(LunchFixtures.ayandaId);
      final write = harness.repository.writtenPicks.single;
      expect(write.picks.length, greaterThanOrEqualTo(20));
      expect(harness.controller.lastAutoFill?.dayCount, 5);
      harness.controller.edit.dismissAutoFill();
      expect(harness.controller.lastAutoFill, isNull);
    });
  });

  group('go-to boxes', () {
    final box = LunchBox({
      LunchSlot.main: LunchPick.of(LunchFixtures.wrap),
      LunchSlot.fruit: LunchPick.of(LunchFixtures.apple),
    });

    test('a box is saved as a favourite in the child’s name', () async {
      await harness.arrive();
      await harness.controller.edit.saveFavourite(
        childId: LunchFixtures.ayandaId,
        name: '  Friday special ',
        box: box,
      );
      final saved = harness.repository.addedFavourites.single;
      expect(saved.name, 'Friday special');
      expect(saved.childId, LunchFixtures.ayandaId);
      expect(saved.picks.keys, {'main', 'fruit'});
      expect(saved.createdBy, Fixtures.samMemberId);
    });

    test('a name longer than the rules keep is said, not sent', () async {
      await harness.arrive();
      await harness.controller.edit.saveFavourite(
        childId: LunchFixtures.ayandaId,
        name: 'x' * (LunchFavourite.nameLimit + 1),
        box: box,
      );
      expect(harness.repository.addedFavourites, isEmpty);
      expect(
        (harness.controller.actionFailure as LunchFailure?)?.problem,
        LunchProblem.nameTooLong,
      );
    });

    test('a child keeps no more than the limit', () async {
      await harness.arrive(
        favourites: [
          for (var i = 0; i < LunchFavourite.perChildLimit; i++)
            LunchFavourite.of(
              id: 'f$i',
              childId: LunchFixtures.ayandaId,
              name: 'Box $i',
              box: box,
              createdBy: Fixtures.samMemberId,
            ),
        ],
      );
      await harness.controller.edit.saveFavourite(
        childId: LunchFixtures.ayandaId,
        name: 'One more',
        box: box,
      );
      expect(harness.repository.addedFavourites, isEmpty);
      expect(
        (harness.controller.actionFailure as LunchFailure?)?.problem,
        LunchProblem.tooManyFavourites,
      );
    });

    test('packing a favourite replaces the whole day', () async {
      await harness.arrive();
      await harness.controller.edit.packFavourite(
        childId: LunchFixtures.ayandaId,
        isoWeekday: 4,
        favourite: LunchFavourite.of(
          id: 'f',
          childId: LunchFixtures.ayandaId,
          name: 'F',
          box: box,
          createdBy: Fixtures.samMemberId,
        ),
      );
      final picks = harness.repository.writtenPicks.single.picks;
      expect(picks.keys, hasLength(5));
      expect(picks[key(4, LunchSlot.main)]!.itemId, 'wrap');
      expect(picks[key(4, LunchSlot.veg)], isNull);
    });

    test('an unsafe favourite is refused for that child', () async {
      await harness.arrive();
      await harness.controller.edit.packFavourite(
        childId: LunchFixtures.lwaziId,
        isoWeekday: 4,
        favourite: LunchFavourite.of(
          id: 'f',
          childId: LunchFixtures.lwaziId,
          name: 'F',
          box: LunchBox({
            LunchSlot.main: LunchPick.of(LunchFixtures.peanutButter),
          }),
          createdBy: Fixtures.samMemberId,
        ),
      );
      expect(harness.repository.writtenPicks, isEmpty);
    });
  });

  group('after school', () {
    test('a thumb records the box in the marker’s name', () async {
      await harness.arrive();
      await harness.controller.edit.markEaten(
        childId: LunchFixtures.ayandaId,
        isoWeekday: 2,
        box: LunchVerdict.left,
        items: {LunchSlot.veg: LunchVerdict.left},
      );
      final write = harness.repository.writtenFeedback.single;
      expect(write.day, 2);
      expect(write.feedback!.verdict, 'left');
      expect(write.feedback!.items, {'veg': 'left'});
      expect(write.feedback!.by, Fixtures.samMemberId);
    });

    test('and can be taken back', () async {
      await harness.arrive();
      await harness.controller.edit.unmarkEaten(
        childId: LunchFixtures.ayandaId,
        isoWeekday: 2,
      );
      expect(harness.repository.writtenFeedback.single.feedback, isNull);
    });

    test('the next suggestion changes because of it', () async {
      final grapes = LunchPick.of(LunchFixtures.grapes);
      await harness.arrive();
      final before = board()
          .childWeek(LunchFixtures.ayandaId)!
          .rank(LunchSlot.fruit, board().library)
          .best!
          .item
          .id;
      harness.repository.emitPlans([
        LunchFixtures.plan(
          LunchFixtures.ayandaId,
          week: LunchWeek.of(LunchFixtures.today).previous,
          slots: {
            key(1, LunchSlot.fruit): grapes,
            key(2, LunchSlot.fruit): grapes,
          },
          feedback: {
            '1': LunchFixtures.feedback(LunchVerdict.left),
            '2': LunchFixtures.feedback(
              LunchVerdict.ate,
              items: {LunchSlot.fruit: LunchVerdict.left},
            ),
          },
        ),
      ]);
      await pumpEventQueue();
      final after = board()
          .childWeek(LunchFixtures.ayandaId)!
          .rank(LunchSlot.fruit, board().library)
          .best!
          .item
          .id;
      expect(before, 'grapes');
      expect(after, 'apple');
    });
  });

  group('the Sunday prep list', () {
    test('sums this week’s boxes for every child, and ticks', () async {
      await harness.arrive(
        plans: [
          LunchFixtures.plan(
            LunchFixtures.lwaziId,
            slots: {key(1, LunchSlot.veg): LunchPick.of(LunchFixtures.carrots)},
          ),
          LunchFixtures.plan(
            LunchFixtures.ayandaId,
            slots: {key(1, LunchSlot.veg): LunchPick.of(LunchFixtures.carrots)},
          ),
          // Last week's is not this week's prep.
          LunchFixtures.plan(
            LunchFixtures.ayandaId,
            week: LunchFixtures.week.previous,
            slots: {key(1, LunchSlot.main): LunchPick.of(LunchFixtures.wrap)},
          ),
        ],
      );
      final list =
          (harness.controller.prepList as AsyncData<LunchPrepList>).value;
      expect(list.batch.single.item.portions, 2);
      expect(list.onHand, isEmpty);
      await harness.controller.edit.setPrepped('carrots', done: true);
      expect(harness.repository.prepTicks.single, (
        week: '2026-W40',
        itemId: 'carrots',
        done: true,
      ));
    });
  });

  group('the library', () {
    test('adds, edits and puts away', () async {
      await harness.arrive();
      await harness.controller.edit.addItem(
        const LunchItemDraft(
          name: 'Sushi',
          slot: LunchSlot.main,
          allergens: {},
        ),
      );
      await harness.controller.edit.updateItem(
        LunchFixtures.apple,
        const LunchItemDraft(
          name: 'Red apple',
          slot: LunchSlot.fruit,
          allergens: {},
        ),
      );
      await harness.controller.edit.setArchived('apple', archived: true);
      expect(harness.repository.addedItems.single.name, 'Sushi');
      expect(harness.repository.updatedItems.single.name, 'Red apple');
      expect(harness.repository.archived.single, (
        itemId: 'apple',
        archived: true,
      ));
    });
  });

  test('choosing a child is remembered, and falls back to the first', () async {
    await harness.arrive();
    expect(harness.controller.selectedChildId, isNotNull);
    harness.controller.selectChild(LunchFixtures.ayandaId);
    expect(harness.controller.selectedChildId, LunchFixtures.ayandaId);
    harness.controller.selectChild('gone');
    expect(harness.controller.selectedChildId, board().children.first.childId);
  });
}
