import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/kid_routines/model/kid_routine.dart';
import 'package:nestprep/features/kid_routines/model/kid_routine_board.dart';
import 'package:nestprep/features/kid_routines/model/kid_routine_draft.dart';
import 'package:nestprep/features/kid_routines/model/kid_routine_slot.dart';
import 'package:nestprep/features/kid_routines/model/kid_routine_step.dart';
import 'package:nestprep/features/todos/model/chore_picture.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_kid_routines.dart';
import '../../../support/household_fixtures.dart';

/// The kid routine as it is stored and as a parent writes it (kid-routines
/// ADR-0001): the keys the rules name, a shape Firestore can store, and a
/// draft that saves exactly what was chosen.
void main() {
  final today = CalendarDate(2026, 11, 14);

  bool isStorable(Object? value) => switch (value) {
    null || num() || bool() || String() || FieldValue() => true,
    final List<Object?> list => list.every(isStorable),
    final Map<Object?, Object?> map =>
      map.keys.every((key) => key is String) && map.values.every(isStorable),
    _ => false,
  };

  group('stored shape', () {
    test('writes exactly the keys the rule names, all storable', () {
      final json = KidRoutineFixtures.morning().toJson();
      expect(json.keys.toSet(), {
        'name',
        'slot',
        'kidIds',
        'firstDate',
        'recurrence',
        'finishBy',
        'points',
        'steps',
        'createdBy',
        'createdAt',
      });
      expect(json['createdAt'], isA<FieldValue>());
      expect(isStorable(json), isTrue);
    });

    test('no time and no stars are still keys the rule reads', () {
      final json = KidRoutineFixtures.morning(
        finishBy: null,
        points: 0,
      ).toJson();
      expect(json.containsKey('finishBy'), isTrue);
      expect(json['finishBy'], isNull);
      expect(json['points'], 0);
    });

    test('a step with no picture or note writes neither key', () {
      final step = const KidRoutineStep(id: 's1', title: 'Shoes on').toJson();
      expect(step.keys.toSet(), {'id', 'title', 'parts'});
      final part = const KidRoutinePart(id: 'p1', text: 'Hat').toJson();
      expect(part.keys.toSet(), {'id', 'text', 'weekdays'});
    });

    test('comes back as it went', () {
      final routine = KidRoutineFixtures.morning();
      final json = routine.toJson()
        ..['id'] = routine.id
        ..remove('createdAt');
      expect(KidRoutine.fromJson(json), routine);
    });

    test('a slot this build does not know reads as the morning', () {
      final json = KidRoutineFixtures.morning().toJson()
        ..['id'] = 'r'
        ..['slot'] = 'midnight'
        ..remove('createdAt');
      expect(KidRoutine.fromJson(json).slot, KidRoutineSlot.morning);
    });
  });

  group('a part of the pack list', () {
    test('with no days is for every day; with days, only those', () {
      const always = KidRoutinePart(id: 'p1', text: 'Lunchbox');
      const wednesdays = KidRoutinePart(id: 'p2', text: 'Kit', weekdays: [3]);
      expect(always.fallsOn(6), isTrue);
      expect(wednesdays.fallsOn(3), isTrue);
      expect(wednesdays.fallsOn(4), isFalse);
    });
  });

  group('starters', () {
    test('every ready-made step has a sticker in the library', () {
      for (final slot in KidRoutineSlot.values) {
        for (final starter in [
          ...KidRoutineCopy.starters(slot),
          ...KidRoutineCopy.extras(slot),
        ]) {
          expect(
            ChorePicture.byId(starter.picture),
            isNotNull,
            reason: '${starter.title} names ${starter.picture}',
          );
          expect(
            starter.title.length,
            lessThanOrEqualTo(KidRoutine.stepTitleLimit),
          );
        }
        expect(
          KidRoutineCopy.starters(slot).length,
          lessThanOrEqualTo(KidRoutine.stepLimit),
        );
      }
    });
  });

  group('draft', () {
    KidRoutineDraft starting() => KidRoutineDraft.starting(
      slot: KidRoutineSlot.morning,
      today: today,
      name: 'Morning',
      starters: KidRoutineCopy.starters(KidRoutineSlot.morning),
      kidIds: {Fixtures.kidMemberId},
    );

    test('a new one starts whole: school days and the starter steps', () {
      final draft = starting();
      expect(draft.isComplete, isTrue);
      expect(draft.weekdays, KidRoutineDraft.schoolDays);
      expect(draft.steps.map((step) => step.id), [
        's1',
        's2',
        's3',
        's4',
        's5',
        's6',
      ]);
      expect(draft.steps.every((step) => step.picture != null), isTrue);
    });

    test('says what is missing', () {
      final draft = KidRoutineDraft(
        slot: KidRoutineSlot.bedtime,
        firstDate: today,
        name: '  ',
        weekdays: const {},
      );
      expect(draft.problems, KidRoutineDraftProblem.values);
    });

    test('saves as a weekly rule on exactly the days picked', () {
      final routine = starting()
          .withWeekdayToggled(6)
          .withFinishBy(435)
          .withPoints(5)
          .toRoutine(createdBy: Fixtures.samMemberId);
      expect(
        routine.recurrence,
        const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          weekdays: [1, 2, 3, 4, 5, 6],
        ),
      );
      expect(routine.finishBy, 435);
      expect(routine.points, 5);
      expect(routine.kidIds, [Fixtures.kidMemberId]);
      expect(routine.firstDate, today);
    });

    test('the time can be cleared again', () {
      expect(starting().withFinishBy(435).withFinishBy(null).finishBy, isNull);
    });

    test('reads a routine back, whatever rule it was saved with', () {
      final stored = KidRoutineFixtures.morning();
      expect(KidRoutineDraft.of(stored).weekdays, {1, 2, 3, 4, 5});
      expect(
        KidRoutineDraft.of(
          stored.copyWith(
            recurrence: const RecurrenceRule(
              frequency: RecurrenceFrequency.daily,
            ),
          ),
        ).weekdays,
        KidRoutineDraft.everyDay,
      );
      expect(
        KidRoutineDraft.of(
          stored.copyWith(
            recurrence: const RecurrenceRule(
              frequency: RecurrenceFrequency.weekly,
            ),
          ),
        ).weekdays,
        {stored.firstDate.weekday},
      );
    });

    test('a step moves, is replaced by id, and is removed', () {
      final draft = starting();
      final moved = draft.withStepMoved(0, 2);
      expect(moved.steps.map((step) => step.id).take(3), ['s2', 's3', 's1']);
      final reworded = draft.withStep(
        const KidRoutineStep(id: 's2', title: 'Clothes on'),
      );
      expect(reworded.steps[1].title, 'Clothes on');
      expect(reworded.steps.length, draft.steps.length);
      expect(draft.withoutStep('s1').steps.first.id, 's2');
    });

    test('a new step never takes an id in use, and stops at the limit', () {
      var draft = starting().withoutStep('s2');
      expect(draft.nextStepId, 's7');
      while (draft.canAddStep) {
        draft = draft.withStep(
          KidRoutineStep(id: draft.nextStepId, title: 'More'),
        );
      }
      expect(draft.steps.length, KidRoutine.stepLimit);
      expect(draft.steps.map((step) => step.id).toSet().length, 12);
      expect(
        draft
            .withStep(const KidRoutineStep(id: 'extra', title: 'One more'))
            .steps
            .length,
        KidRoutine.stepLimit,
      );
    });

    test('a copy is a new routine for nobody yet', () {
      final copy = KidRoutineDraft.of(KidRoutineFixtures.morning())
          .asCopy(name: 'Morning (copy)', today: today);
      expect(copy.id, isNull);
      expect(copy.kidIds, isEmpty);
      expect(copy.steps.length, 3);
      expect(copy.points, 3);
      expect(copy.firstDate, today);
    });
  });

  group('board', () {
    test('a shared routine is under every child it names, by slot', () {
      final sibling = Fixtures.kid.copyWith(id: 'm-kid-2', displayName: 'Leo');
      final board = KidRoutineBoard(
        routines: [
          KidRoutineFixtures.morning(
            kidIds: const [Fixtures.kidMemberId, 'm-kid-2'],
          ),
          KidRoutineFixtures.morning(id: 'weekend', name: 'A weekend morning'),
        ],
        members: [Fixtures.sam, Fixtures.kid, sibling],
      );
      expect(board.kids.map((kid) => kid.id), [
        Fixtures.kidMemberId,
        'm-kid-2',
      ]);
      expect(
        board
            .routinesFor(Fixtures.kidMemberId, KidRoutineSlot.morning)
            .map((routine) => routine.id),
        ['weekend', 'morning'],
      );
      expect(
        board.routinesFor('m-kid-2', KidRoutineSlot.morning).single.id,
        'morning',
      );
      expect(board.routinesFor('m-kid-2', KidRoutineSlot.bedtime), isEmpty);
    });
  });

  group('words', () {
    test('the days read as a parent would say them', () {
      expect(KidRoutineCopy.daysSummary({1, 2, 3, 4, 5}), 'School days');
      expect(KidRoutineCopy.daysSummary({6, 7}), 'Weekends');
      expect(KidRoutineCopy.daysSummary({1, 2, 3, 4, 5, 6, 7}), 'Every day');
      expect(KidRoutineCopy.daysSummary({3, 1}), 'Mon, Wed');
    });
  });
}
