import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_board.dart';
import 'package:nestprep/features/lunch_box/model/lunch_choices.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_planning_harness.dart';

/// A parent's side of kid picks (lunch-box ADR-0008): two or three options,
/// never an unsafe one, and *Suggest options* a day per write.
void main() {
  late LunchPlanningHarness harness;

  setUp(() => harness = LunchPlanningHarness());
  tearDown(() => harness.close());

  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);

  Future<void> arrive([List<LunchChoices> choices = const []]) async {
    harness.lunch.emit();
    harness.emitPlanning(choices: choices);
    await pumpEventQueue();
  }

  LunchChildWeek childWeek(String childId) =>
      (harness.board.board as AsyncData<LunchBoard>).value.childWeek(childId)!;

  test('holds each child’s options for the board’s week', () async {
    await arrive([
      LunchChoices.none(
        childId: LunchFixtures.lwaziId,
        week: LunchFixtures.week,
      ).copyWith(
        options: {
          key(2, LunchSlot.fruit): [
            LunchPick.of(LunchFixtures.apple),
            LunchPick.of(LunchFixtures.grapes),
          ],
        },
      ),
    ]);
    expect(harness.choicesRepository.watchedWeeks, [LunchFixtures.week.key]);
    expect(
      harness.choices
          .choicesFor(LunchFixtures.lwaziId, LunchFixtures.week)
          .optionsAt(2, LunchSlot.fruit),
      hasLength(2),
    );
    expect(
      harness.choices
          .choicesFor(LunchFixtures.ayandaId, LunchFixtures.week)
          .isEmpty,
      isTrue,
    );
  });

  test('offers two or three, and says so otherwise', () async {
    await arrive();
    final lwazi = childWeek(LunchFixtures.lwaziId);
    await harness.choices.setOptions(
      childWeek: lwazi,
      isoWeekday: 2,
      slot: LunchSlot.fruit,
      items: [LunchFixtures.apple],
    );
    expect(
      (harness.choices.actionFailure as LunchPlanningFailure?)?.problem,
      LunchPlanningProblem.wrongNumberOfOptions,
    );
    await harness.choices.setOptions(
      childWeek: lwazi,
      isoWeekday: 2,
      slot: LunchSlot.fruit,
      items: [LunchFixtures.apple, LunchFixtures.grapes],
    );
    final write = harness.choicesRepository.setOptionsWrites.single;
    expect(write.options.keys, [key(2, LunchSlot.fruit)]);
    expect(write.options.values.single!.map((p) => p.itemId), [
      'apple',
      'grapes',
    ]);
  });

  test('never offers what is unsafe for the child', () async {
    await arrive();
    await harness.choices.setOptions(
      childWeek: childWeek(LunchFixtures.lwaziId),
      isoWeekday: 3,
      slot: LunchSlot.main,
      items: [LunchFixtures.wrap, LunchFixtures.peanutButter],
    );
    expect(harness.choicesRepository.setOptionsWrites, isEmpty);
    expect(
      (harness.choices.actionFailure as LunchFailure?)?.problem,
      LunchProblem.unsafeForChild,
    );
  });

  test('a rules refusal says an option is not safe any more', () async {
    await arrive();
    harness.choicesRepository.failWritesWith = const PermissionDeniedFailure();
    await harness.choices.setOptions(
      childWeek: childWeek(LunchFixtures.lwaziId),
      isoWeekday: 2,
      slot: LunchSlot.fruit,
      items: [LunchFixtures.apple, LunchFixtures.grapes],
    );
    expect(
      (harness.choices.actionFailure as LunchPlanningFailure?)?.problem,
      LunchPlanningProblem.optionNotSafe,
    );
  });

  test('suggest options writes one day at a time, from today', () async {
    await arrive();
    await harness.choices.suggestWeek(childWeek(LunchFixtures.lwaziId));
    final writes = harness.choicesRepository.setOptionsWrites;
    expect(writes, hasLength(4));
    expect(writes.map((write) => write.day), [2, 3, 4, 5]);
    for (final write in writes) {
      expect(
        write.options.keys.every((key) => key.startsWith('${write.day}_')),
        isTrue,
      );
    }
    expect(harness.choices.isSuggesting, isFalse);
  });

  test('clearing a compartment takes its options away', () async {
    await arrive();
    await harness.choices.clearOptions(
      childId: LunchFixtures.lwaziId,
      isoWeekday: 2,
      slot: LunchSlot.fruit,
    );
    expect(harness.choicesRepository.setOptionsWrites.single.options, {
      key(2, LunchSlot.fruit): null,
    });
  });
}
