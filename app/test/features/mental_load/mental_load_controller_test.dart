import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/mental_load/model/week_load.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../support/household_fixtures.dart';
import '../../support/mental_load_fixtures.dart';
import '../../support/mental_load_harness.dart';

/// The shared week's controller (calendar ADR-0006): it waits for every read
/// before it says anything, follows the week it is shown, and writes nothing.
void main() {
  late MentalLoadHarness harness;

  setUp(() => harness = MentalLoadHarness());
  tearDown(() => harness.close());

  WeekLoad loaded() => switch (harness.controller.week) {
    AsyncData(:final value) => value,
    final other => throw StateError('not loaded: $other'),
  };

  test('is loading until every read has answered', () async {
    expect(harness.controller.week, isA<AsyncLoading<WeekLoad>>());
    harness.calendar.emitEvents(const []);
    await pumpEventQueue();
    expect(harness.controller.week, isA<AsyncLoading<WeekLoad>>());
    harness.answer();
    await pumpEventQueue();
    expect(harness.controller.week, isA<AsyncData<WeekLoad>>());
  });

  test('derives the week from the four features’ reads', () async {
    harness.answerABusyWeek();
    await pumpEventQueue();
    final week = loaded();
    final sam = week.adults.first;
    expect(sam.member.id, Fixtures.samMemberId);
    expect(sam.countOf(LoadKind.eventsPlanned), 1);
    expect(sam.countOf(LoadKind.eventsAttended), 1);
    expect(sam.countOf(LoadKind.todosDone), 1);
    final alex = week.adults.last;
    expect(alex.countOf(LoadKind.todosWaiting), 1);
    expect(alex.countOf(LoadKind.groceriesBought), 1);
    expect(alex.countOf(LoadKind.groceriesAdded), 0, reason: 'no addedAt yet');
  });

  test('reads the windowed collections for the week it shows', () async {
    harness.answer();
    await pumpEventQueue();
    expect(harness.todos.completionsFrom, LoadFixtures.weekStart);
    expect(harness.calendar.exceptionWindows.last.from, LoadFixtures.weekStart);
    expect(harness.controller.isThisWeek, isTrue);

    harness.controller.goToNextWeek();
    expect(harness.controller.week, isA<AsyncLoading<WeekLoad>>());
    await pumpEventQueue();
    final next = LoadFixtures.weekStart.addDays(7);
    expect(harness.todos.completionsFrom, next);
    expect(harness.calendar.exceptionWindows.last.from, next);
    expect(harness.controller.isThisWeek, isFalse);

    harness.controller.goToThisWeek();
    expect(harness.controller.weekStart, LoadFixtures.weekStart);
    harness.controller.goToPreviousWeek();
    expect(harness.controller.weekStart, LoadFixtures.weekStart.addDays(-7));
  });

  test('a failed read is the week’s failure, and retry reads again', () async {
    harness.answer();
    harness.calendar.failEventsWith(const PermissionDeniedFailure());
    await pumpEventQueue();
    expect(harness.controller.week, isA<AsyncFailure<WeekLoad>>());
    await harness.controller.retry();
    harness.answer();
    await pumpEventQueue();
    expect(harness.controller.week, isA<AsyncData<WeekLoad>>());
  });

  test(
    'without the nanny hub, carer shifts are empty rather than read',
    () async {
      final noCare = MentalLoadHarness(includeCare: false);
      addTearDown(noCare.close);
      noCare.answer();
      await pumpEventQueue();
      expect(noCare.controller.week, isA<AsyncData<WeekLoad>>());
      expect(noCare.shifts.openShifts.hasListener, isFalse);
    },
  );

  test('a renamed parent is renamed on the card with no read', () async {
    harness.answer();
    await pumpEventQueue();
    harness.controller.showMembers([
      Fixtures.sam.copyWith(displayName: 'Sam P'),
      LoadFixtures.alex,
    ]);
    expect(loaded().adults.first.member.displayName, 'Sam P');
  });

  group('sharing a card', () {
    test('hands the picture and the words to the share sheet', () async {
      await harness.controller.share(
        png: Uint8List.fromList([1, 2, 3]),
        text: 'Sam’s week',
      );
      expect(harness.sharer.shared.single.bytes, 3);
      expect(harness.sharer.shared.single.fileName, contains('2026-09-28'));
      expect(harness.controller.actionFailure, isNull);
    });

    test('a card that could not be drawn is said, not shared', () async {
      await harness.controller.share(png: null, text: 'x');
      expect(harness.sharer.shared, isEmpty);
      expect(harness.controller.actionFailure, isA<MentalLoadFailure>());
    });

    test('a share sheet that will not open is said', () async {
      harness.sharer.failWith = const MentalLoadFailure(
        MentalLoadProblem.shareUnavailable,
      );
      await harness.controller.share(png: Uint8List(1), text: 'x');
      expect(harness.controller.actionFailure, isA<MentalLoadFailure>());
    });
  });
}
