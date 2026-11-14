import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/kid_routines/model/kid_routine_run.dart';
import 'package:nestprep/features/kid_routines/model/kid_routine_slot.dart';
import 'package:nestprep/features/kid_routines/model/kid_routine_tick.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_kid_routines.dart';
import '../../../support/household_fixtures.dart';

void main() {
  const kid = Fixtures.kidMemberId;
  final wednesday = CalendarDate(2026, 11, 4);
  final saturday = CalendarDate(2026, 11, 7);
  final morning = KidRoutineFixtures.morning();

  KidRoutineTick tick(List<String> done, {String kidId = kid}) =>
      KidRoutineTick(
        routineId: 'morning',
        kidId: kidId,
        occurrenceDate: wednesday,
        doneStepIds: done,
        updatedBy: kid,
      );

  List<KidRoutineRun> day({
    List<KidRoutineTick> ticks = const [],
    CalendarDate? on,
  }) => KidRoutineRun.forDay(
    routines: [
      morning.copyWith(
        id: 'bed',
        name: 'Bedtime',
        slot: KidRoutineSlot.bedtime,
      ),
      morning,
      morning.copyWith(id: 'other', kidIds: ['someone-else']),
    ],
    ticks: ticks,
    kidId: kid,
    date: on ?? wednesday,
  );

  test('a tick is keyed by routine, child and day, and writes the six '
      'fields the rules keep', () {
    final written = tick(['s1']);
    expect(written.id, 'morning_${kid}_2026-11-04');
    expect(written.toJson().keys.toSet(), {
      'routineId',
      'kidId',
      'occurrenceDate',
      'doneStepIds',
      'updatedBy',
      'updatedAt',
    });
    expect(written.toJson()['occurrenceDate'], '2026-11-04');
  });

  test('a day holds only the child’s own routines, in the order a day '
      'runs', () {
    expect([for (final run in day()) run.routine.id], ['morning', 'bed']);
  });

  test('a routine is not on a day it does not repeat on', () {
    expect(day(on: saturday), isEmpty);
    expect(day(on: CalendarDate(2026, 10, 30)), isEmpty);
  });

  test('another child’s tick and another day’s tick do not count', () {
    final runs = day(
      ticks: [
        tick(['s1', 's2'], kidId: 'someone-else'),
        tick(['s1']).copyWith(occurrenceDate: saturday),
      ],
    );
    expect(runs.first.doneCount, 0);
  });

  test('progress follows the tick, and the page is the first open step', () {
    final run = day(
      ticks: [
        tick(['s1']),
      ],
    ).first;
    expect(run.doneCount, 1);
    expect(run.currentIndex, 1);
    expect(run.isFinished, isFalse);
    expect(run.finishesWith(run.steps[1]), isFalse);
  });

  test('a step the routine no longer has neither counts nor finishes '
      'it', () {
    final run = day(
      ticks: [
        tick(['s1', 's2', 'gone']),
      ],
    ).first;
    expect(run.doneCount, 2);
    expect(run.isFinished, isFalse);
    expect(run.finishesWith(run.steps[2]), isTrue);
    expect(run.doneAfterToggling(run.steps[2]), ['s1', 's2', 's3']);
  });

  test('toggling writes the done list in the routine’s order, and '
      'unticks', () {
    final run = day(
      ticks: [
        tick(['s3', 's1']),
      ],
    ).first;
    expect(run.doneAfterToggling(run.steps[1]), ['s1', 's2', 's3']);
    expect(run.doneAfterToggling(run.steps[0]), ['s3']);
  });

  test('a finished routine rests on its last step', () {
    final run = day(
      ticks: [
        tick(['s1', 's2', 's3']),
      ],
    ).first;
    expect(run.isFinished, isTrue);
    expect(run.currentIndex, 2);
  });

  test('a thing to remember shows only on its days', () {
    final wed = day().first;
    expect(
      [for (final p in wed.partsOf(wed.steps[2])) p.text],
      ['Lunchbox', 'Swimming kit'],
    );
    final thu = day(on: CalendarDate(2026, 11, 5)).first;
    expect([for (final p in thu.partsOf(thu.steps[2])) p.text], ['Lunchbox']);
  });
}
