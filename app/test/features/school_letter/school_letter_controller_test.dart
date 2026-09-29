import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/school_letter/data/letter_picker.dart';
import 'package:nestprep/features/school_letter/model/letter_proposal.dart';
import 'package:nestprep/features/school_letter/model/letter_reading.dart';
import 'package:nestprep/features/school_letter/state/school_letter_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../support/fake_calendar_repository.dart';
import '../../support/fake_calendar_v2.dart';

/// Snap a school letter's controller (calendar ADR-0005): a letter is read,
/// the proposals are reviewed, and **only what the parent ticked and
/// confirmed** is added — as ordinary events, by the person confirming.
void main() {
  late FakeSchoolLetterReader reader;
  late FakeLetterPicker picker;
  late FakeCalendarRepository calendar;
  late SchoolLetterController controller;

  setUp(() {
    reader = FakeSchoolLetterReader()
      ..reading = LetterReading(proposals: twoProposals(), callsLeft: 7);
    picker = FakeLetterPicker();
    calendar = FakeCalendarRepository();
    controller = SchoolLetterController(
      schoolLetterReader: reader,
      letterPicker: picker,
      calendarRepository: calendar,
      householdId: 'h1',
      memberId: 'm-sam',
    );
  });

  tearDown(() async {
    controller.dispose();
    await calendar.close();
  });

  group('reading a letter', () {
    test(
      'picks, reads, and lands on the review with everything ticked',
      () async {
        await controller.pick(LetterSource.camera);
        expect(picker.asked, [LetterSource.camera]);
        expect(reader.requests.single.householdId, 'h1');
        expect(controller.step, LetterStep.review);
        expect(controller.items.map((item) => item.proposal.title), [
          'Grade 3 zoo outing',
          'Civvies day',
        ]);
        expect(controller.tickedCount, 2);
        expect(controller.callsLeft, 7);
        expect(calendar.savedEvents, isEmpty, reason: 'nothing saved yet');
      },
    );

    test('shows the reading step while the model has it', () async {
      reader.gate = Completer<void>();
      final reading = controller.pick(LetterSource.pdf);
      await Future<void>.delayed(Duration.zero);
      expect(controller.step, LetterStep.reading);
      reader.complete();
      await reading;
      expect(controller.step, LetterStep.review);
    });

    test('backing out of the picker changes nothing', () async {
      picker.next = null;
      await controller.pick(LetterSource.photos);
      expect(controller.step, LetterStep.choosing);
      expect(reader.requests, isEmpty);
      expect(controller.failure, isNull);
    });

    test(
      'a picker that will not open says so, with nothing to resend',
      () async {
        picker.failWith = const SchoolLetterFailure(
          SchoolLetterProblem.pickerUnavailable,
        );
        await controller.pick(LetterSource.camera);
        expect(controller.step, LetterStep.choosing);
        expect(controller.failure, isA<SchoolLetterFailure>());
        expect(controller.canRetry, isFalse);
      },
    );

    test(
      'a read that fails comes back to the choice, and can be retried',
      () async {
        reader.failWith = const AiFailure(AiProblem.aiUnavailable);
        await controller.pick(LetterSource.camera);
        expect(controller.step, LetterStep.choosing);
        expect(controller.failure, const TypeMatcher<AiFailure>());
        expect(controller.canRetry, isTrue);

        reader.failWith = null;
        await controller.retry();
        expect(reader.requests, hasLength(2));
        expect(reader.requests.last.letter, same(aLetter));
        expect(controller.step, LetterStep.review);
        expect(controller.failure, isNull);
      },
    );

    test('a letter with no dates is an empty review, not a failure', () async {
      reader.reading = const LetterReading(proposals: [], callsLeft: 3);
      await controller.pick(LetterSource.camera);
      expect(controller.step, LetterStep.review);
      expect(controller.items, isEmpty);
      await controller.confirm();
      expect(controller.step, LetterStep.review);
    });
  });

  group('reviewing', () {
    setUp(() => controller.pick(LetterSource.camera));

    test('unticking leaves an event out, and ticking brings it back', () {
      controller.toggle(1);
      expect(controller.tickedCount, 1);
      controller.toggle(1);
      expect(controller.tickedCount, 2);
    });

    test('an edited proposal replaces the original and is ticked', () {
      controller.toggle(0);
      final edited = LetterProposal(
        title: 'Zoo outing',
        date: CalendarDate(2026, 10, 22),
      );
      controller.replace(0, edited);
      expect(controller.items.first.proposal, edited);
      expect(controller.items.first.isTicked, isTrue);
      expect(controller.items.first.key, 0);
    });
  });

  group('confirming', () {
    setUp(() => controller.pick(LetterSource.camera));

    test('adds only the ticked events, as the person confirming', () async {
      controller.toggle(1);
      await controller.confirm();
      expect(calendar.savedEvents.map((event) => event.title), [
        'Grade 3 zoo outing',
      ]);
      final saved = calendar.savedDetails.single;
      expect(saved.createdBy, 'm-sam');
      expect(saved.memberIds, ['m-kid']);
      expect(saved.note, 'Bring a hat');
      expect(saved.endMinute, 13 * 60);
      expect(controller.step, LetterStep.done);
      expect(controller.added, 1);
    });

    test('with nothing ticked does nothing', () async {
      controller
        ..toggle(0)
        ..toggle(1);
      await controller.confirm();
      expect(calendar.savedEvents, isEmpty);
      expect(controller.step, LetterStep.review);
    });

    test(
      'that half fails keeps the unsaved ones ticked, and says so',
      () async {
        calendar.refuseTitles.add('Civvies day');
        await controller.confirm();
        expect(calendar.savedEvents.map((event) => event.title), [
          'Grade 3 zoo outing',
        ]);
        expect(controller.step, LetterStep.review);
        expect(controller.items.map((item) => item.proposal.title), [
          'Civvies day',
        ]);
        expect(
          controller.failure,
          isA<SchoolLetterFailure>().having(
            (failure) => failure.problem,
            'problem',
            SchoolLetterProblem.someNotAdded,
          ),
        );

        // Confirming again finishes the job without adding anything twice.
        calendar.refuseTitles.clear();
        await controller.confirm();
        expect(calendar.savedEvents.map((event) => event.title), [
          'Grade 3 zoo outing',
          'Civvies day',
        ]);
        expect(controller.step, LetterStep.done);
      },
    );

    test('starting over clears the list for another letter', () async {
      await controller.confirm();
      controller.startOver();
      expect(controller.step, LetterStep.choosing);
      expect(controller.items, isEmpty);
      expect(controller.canRetry, isFalse);
    });

    test('the failure can be dismissed', () async {
      calendar.refuseTitles.add('Civvies day');
      await controller.confirm();
      controller.dismissFailure();
      expect(controller.failure, isNull);
    });
  });
}
