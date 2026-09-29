import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_choice_day.dart';
import 'package:nestprep/features/lunch_box/model/lunch_choices.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/state/lunch_choose_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_lunch_planning.dart';
import '../../../support/fake_lunch_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';

/// A child choosing (lunch-box ADR-0008): exactly the two documents their
/// grant opens, only the approved options written, a celebration when a day
/// is done, and nothing opened when there is nothing to show.
void main() {
  late FakeLunchRepository plans;
  late FakeLunchChoicesRepository choices;
  late LunchChooseController controller;

  final apple = LunchPick.of(LunchFixtures.apple);
  final grapes = LunchPick.of(LunchFixtures.grapes);
  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);

  setUp(() {
    plans = FakeLunchRepository();
    choices = FakeLunchChoicesRepository();
    controller = LunchChooseController(
      lunchRepository: plans,
      choicesRepository: choices,
      householdId: Fixtures.householdId,
      childId: LunchFixtures.lwaziId,
    );
  });

  tearDown(() async {
    controller.dispose();
    await plans.close();
    await choices.close();
  });

  LunchChoices offered() =>
      LunchChoices.none(
        childId: LunchFixtures.lwaziId,
        week: LunchFixtures.week,
      ).copyWith(
        options: {
          key(2, LunchSlot.fruit): [apple, grapes],
        },
      );

  Future<void> open() async {
    controller.follow(today: LunchFixtures.today);
    await pumpEventQueue();
    plans.emitPlan(LunchFixtures.plan(LunchFixtures.lwaziId));
    choices.emitChoices(offered());
    await pumpEventQueue();
  }

  List<LunchChoiceDay> days() =>
      (controller.days as AsyncData<List<LunchChoiceDay>>).value;

  test(
    'reads the child’s own plan and options for the week being planned',
    () async {
      await open();
      expect(plans.watchedPlans, isNotEmpty);
      expect(choices.watchedChoices, ['${LunchFixtures.lwaziId}_2026-W40']);
      expect(days().single.date.weekday, 2);
    },
  );

  test('writes an approved option into the plan, and nothing else', () async {
    await open();
    await controller.choose(isoWeekday: 2, slot: LunchSlot.fruit, pick: grapes);
    await controller.choose(
      isoWeekday: 2,
      slot: LunchSlot.fruit,
      pick: LunchPick.of(LunchFixtures.biltong),
    );
    expect(choices.chosen.single.pick.itemId, 'grapes');
  });

  test('finishing a day is celebrated once, straight away', () async {
    await open();
    expect(controller.celebrations, 0);
    await controller.choose(isoWeekday: 2, slot: LunchSlot.fruit, pick: apple);
    expect(controller.celebrations, 1);
  });

  test('a refused pick is said in a child’s words', () async {
    await open();
    choices.failWritesWith = const PermissionDeniedFailure();
    await controller.choose(isoWeekday: 2, slot: LunchSlot.fruit, pick: apple);
    expect(
      (controller.actionFailure as LunchPlanningFailure?)?.problem,
      LunchPlanningProblem.notAnOption,
    );
  });

  test('opens nothing when there is nothing to show', () async {
    controller.follow(today: LunchFixtures.today, show: false);
    await pumpEventQueue();
    expect(days(), isEmpty);
    expect(choices.watchedChoices, isEmpty);
  });

  test(
    'can learn today from a stream — a kid device’s household zone',
    () async {
      final todays = StreamController<CalendarDate>();
      final fromStream = LunchChooseController(
        lunchRepository: plans,
        choicesRepository: choices,
        householdId: Fixtures.householdId,
        childId: LunchFixtures.lwaziId,
        todays: todays.stream,
      );
      addTearDown(() async {
        fromStream.dispose();
        await todays.close();
      });
      todays.add(LunchFixtures.today);
      await pumpEventQueue();
      expect(choices.watchedChoices, ['${LunchFixtures.lwaziId}_2026-W40']);
    },
  );

  test('a failed read is a failure, and retry opens the reads again', () async {
    await open();
    choices.failChoicesWith(const UnavailableFailure());
    await pumpEventQueue();
    expect(controller.days, isA<AsyncFailure<List<LunchChoiceDay>>>());
    await controller.retry();
    expect(controller.days, isA<AsyncLoading<List<LunchChoiceDay>>>());
  });
}
