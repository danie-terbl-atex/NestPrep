import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/kid_routines/model/kid_routine_tick.dart';
import 'package:nestprep/features/kid_routines/state/kid_routine_day_controller.dart';
import 'package:nestprep/features/kid_routines/ui/kid_routine_player.dart';
import 'package:nestprep/features/kid_routines/ui/kid_routines_today.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/kid_copy.dart';
import 'package:nestprep/shared/copy/points_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_kid_routines.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// A child's routines on their home and the one-step-at-a-time player
/// (kid-routines ADR-0001).
void main() {
  const kid = Fixtures.kidMemberId;
  final wednesday = CalendarDate(2026, 11, 4);

  late FakeKidRoutineRepository repository;
  late KidRoutineDayController controller;

  setUp(() {
    repository = FakeKidRoutineRepository();
    controller = KidRoutineDayController(
      repository: repository,
      householdId: Fixtures.householdId,
      kidId: kid,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  KidRoutineTick tick(List<String> done) => KidRoutineTick(
    routineId: 'morning',
    kidId: kid,
    occurrenceDate: wednesday,
    doneStepIds: done,
    updatedBy: kid,
  );

  Future<void> pump(
    WidgetTester tester, {
    List<String> done = const [],
    bool canTick = true,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    controller.follow(show: true, canTick: canTick, today: wednesday);
    await pumpScreen(
      tester,
      NestScaffold(
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => ListView(
            children: [
              KidRoutinesToday(controller: controller, kidName: 'Mia Nkosi'),
            ],
          ),
        ),
      ),
      providers: const [],
      brightness: brightness,
      textScale: scale,
    );
    await tester.pump();
    repository
      ..emit([KidRoutineFixtures.morning()])
      ..emitTicks([if (done.isNotEmpty) tick(done)]);
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('kid-routine-morning')));
    await tester.pumpAndSettle();
  }

  testWidgets('takes no room before the read answers, and none on a day '
      'with no routine', (tester) async {
    controller.follow(show: true, canTick: true, today: wednesday);
    await pumpScreen(
      tester,
      NestScaffold(
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) =>
              KidRoutinesToday(controller: controller, kidName: 'Mia'),
        ),
      ),
      providers: const [],
    );
    await tester.pump();
    expect(find.text(KidRoutineCopy.kidTitle), findsNothing);
    repository
      ..emit([])
      ..emitTicks([]);
    await tester.pumpAndSettle();
    expect(find.text(KidRoutineCopy.kidTitle), findsNothing);
  });

  testWidgets('asks only for the routines naming this child', (tester) async {
    await pump(tester);
    expect(repository.watchedKids, [kid]);
  });

  testWidgets('the card says how far along the routine is and what it is '
      'worth', (tester) async {
    await pump(tester, done: ['s1']);
    expect(find.text('Morning'), findsOneWidget);
    expect(
      find.textContaining(KidRoutineCopy.kidProgress(1, 3)),
      findsOneWidget,
    );
    expect(find.text(PointsCopy.starsCount(3)), findsOneWidget);
    expect(find.text(KidRoutineCopy.kidKeepGoing), findsOneWidget);
  });

  testWidgets('opens on the first step not yet done', (tester) async {
    await pump(tester, done: ['s1']);
    await open(tester);
    expect(find.text('Brush teeth'), findsOneWidget);
    expect(find.text(KidRoutineCopy.kidStepOf(2, 3).toUpperCase()), findsOneWidget);
    expect(
      find.text(KidRoutineCopy.kidNext('Pack school bag')),
      findsOneWidget,
    );
  });

  testWidgets('Done ticks the step as this child and moves on', (tester) async {
    await pump(tester);
    await open(tester);
    await tester.tap(find.byKey(KidRoutinePlayer.doneKey));
    await tester.pumpAndSettle();
    final saved = repository.savedTicks.single;
    expect(saved.id, 'morning_${kid}_2026-11-04');
    expect(saved.doneStepIds, ['s1']);
    expect(saved.updatedBy, kid);
    expect(find.text(KidRoutineCopy.kidStepOf(2, 3).toUpperCase()), findsOneWidget);
  });

  testWidgets('a step shows its note and today’s things to remember, which '
      'tick off on the page only', (tester) async {
    await pump(tester, done: ['s1', 's2']);
    await open(tester);
    expect(find.text('Check the diary first'), findsOneWidget);
    expect(find.text('Lunchbox'), findsOneWidget);
    expect(find.text('Swimming kit'), findsOneWidget);
    await tester.ensureVisible(find.text('Swimming kit'));
    await tester.tap(find.text('Swimming kit'));
    await tester.pumpAndSettle();
    expect(repository.savedTicks, isEmpty);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Swimming kit')),
      matchesSemantics(
        label: 'Swimming kit',
        isButton: true,
        hasCheckedState: true,
        isChecked: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('the last step celebrates with the stars and closes', (
    tester,
  ) async {
    await pump(tester, done: ['s1', 's2']);
    await open(tester);
    await tester.tap(find.byKey(KidRoutinePlayer.doneKey));
    await tester.pump();
    expect(find.text(KidCopy.allDone('Mia')), findsOneWidget);
    expect(find.text(PointsCopy.plusStars(3)), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(repository.savedTicks.single.doneStepIds, ['s1', 's2', 's3']);
    expect(find.byKey(KidRoutinePlayer.doneKey), findsNothing);
    expect(find.text(KidRoutineCopy.kidAllDone), findsWidgets);
  });

  testWidgets('a step tapped on the path can be unticked', (tester) async {
    await pump(tester, done: ['s1']);
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('kid-routine-path-s1')));
    await tester.pumpAndSettle();
    expect(find.text(KidRoutineCopy.kidStepIsDone), findsOneWidget);
    await tester.tap(find.byKey(KidRoutinePlayer.undoKey));
    await tester.pumpAndSettle();
    expect(repository.savedTicks.single.doneStepIds, isEmpty);
    expect(find.byKey(KidRoutinePlayer.doneKey), findsOneWidget);
  });

  testWidgets('a refused tick says so and keeps the page', (tester) async {
    repository.tickFailure = const PermissionDeniedFailure();
    await pump(tester, done: ['s1', 's2']);
    await open(tester);
    await tester.tap(find.byKey(KidRoutinePlayer.doneKey));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
    expect(find.byKey(KidRoutinePlayer.doneKey), findsOneWidget);
  });

  testWidgets('a grant that only looks shows the steps and no button', (
    tester,
  ) async {
    await pump(tester, canTick: false);
    expect(find.text(KidRoutineCopy.kidStart), findsNothing);
    await open(tester);
    expect(find.text('Get dressed'), findsOneWidget);
    expect(find.byKey(KidRoutinePlayer.doneKey), findsNothing);
  });

  group('dark, 200% text, 360 wide', () {
    testWidgets('the card and the player hold', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pump(
        tester,
        done: ['s1', 's2'],
        brightness: Brightness.dark,
        scale: 2,
      );
      expect(tester.takeException(), isNull);
      await open(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Pack school bag'), findsOneWidget);
    });
  });
}
