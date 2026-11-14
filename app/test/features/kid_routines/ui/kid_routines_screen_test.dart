import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/kid_routines/model/kid_routine_draft.dart';
import 'package:nestprep/features/kid_routines/model/kid_routine_slot.dart';
import 'package:nestprep/features/kid_routines/state/kid_routines_controller.dart';
import 'package:nestprep/features/kid_routines/ui/kid_routines_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/points_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_kid_routines.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/test_flags.dart';

/// The parent's routines screen (kid-routines ADR-0001) in its four states,
/// and the three things a parent does there: set one up from the ready-made
/// start, change one, delete one.
void main() {
  const kid = Fixtures.kidMemberId;

  late FakeKidRoutineRepository repository;
  late KidRoutinesController controller;

  KidRoutinesController controllerFor({
    bool canEdit = true,
    bool setsStars = true,
  }) => KidRoutinesController(
    repository: repository,
    householdId: Fixtures.householdId,
    memberId: Fixtures.samMemberId,
    canEdit: canEdit,
    setsStars: setsStars,
    members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
  );

  setUp(() {
    repository = FakeKidRoutineRepository();
    controller = controllerFor();
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
    FeatureFlagsController? flags,
  }) => pumpScreen(
    tester,
    const KidRoutinesScreen(),
    providers: [
      if (flags != null)
        ChangeNotifierProvider<FeatureFlagsController>.value(value: flags),
      ChangeNotifierProvider<KidRoutinesController>.value(value: controller),
    ],
    brightness: brightness,
    textScale: scale,
  );

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('holds the layout while it loads', (tester) async {
    await pump(tester);
    await tester.pump();
    expect(find.byKey(const ValueKey('loading')), findsOneWidget);
    expect(find.text(KidRoutineCopy.title), findsOneWidget);
  });

  testWidgets('an error offers a retry, in words', (tester) async {
    await pump(tester);
    repository.failWith(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.failure(const UnavailableFailure())), findsOne);
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('a household with no child says to add one', (tester) async {
    controller.dispose();
    controller = KidRoutinesController(
      repository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      canEdit: true,
      setsStars: true,
      members: [Fixtures.sam, Fixtures.thandi],
    );
    await pump(tester);
    repository.emit(const []);
    await tester.pumpAndSettle();
    expect(find.text(KidRoutineCopy.noKidsTitle), findsOneWidget);
  });

  testWidgets('switched off says so and shows nothing else', (tester) async {
    final flags = testFlagsController(TestFlags.off);
    addTearDown(flags.dispose);
    await pump(tester, flags: flags);
    repository.emit([KidRoutineFixtures.morning()]);
    await tester.pumpAndSettle();
    expect(find.text(KidRoutineCopy.switchedOffTitle), findsOneWidget);
    expect(find.text('Morning'), findsNothing);
  });

  testWidgets(
    'a child with nothing yet is offered all three parts of the day',
    (tester) async {
      await pump(tester);
      repository.emit(const []);
      await tester.pumpAndSettle();
      expect(find.text(Fixtures.kid.displayName), findsOneWidget);
      for (final slot in KidRoutineSlot.values) {
        expect(find.text(KidRoutineCopy.setUp(slot)), findsOneWidget);
      }
    },
  );

  testWidgets(
    'setting up a morning saves the ready-made steps for that child',
    (tester) async {
      await pump(tester);
      repository.emit(const []);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('kid-routine-set-up-$kid-morning')),
      );
      await tester.pumpAndSettle();
      expect(find.text(KidRoutineCopy.newRoutine), findsOneWidget);
      expect(find.text('Brush teeth'), findsOneWidget);

      final stars = find.byKey(const ValueKey('kid-routine-stars-5'));
      await reveal(tester, stars);
      await tester.tap(stars);
      final save = find.byKey(const ValueKey('kid-routine-save'));
      await reveal(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final saved = repository.saved.single;
      expect(saved.id, isEmpty);
      expect(saved.name, 'Morning');
      expect(saved.slot, KidRoutineSlot.morning);
      expect(saved.kidIds, [kid]);
      expect(saved.points, 5);
      expect(saved.createdBy, Fixtures.samMemberId);
      expect(saved.recurrence?.weekdays, [1, 2, 3, 4, 5]);
      expect(saved.steps.map((step) => step.picture), [
        'wake-up-alarm',
        'get-dressed',
        'eat-breakfast',
        'brush-teeth',
        'pack-school-bag',
        'put-on-shoes',
      ]);
    },
  );

  testWidgets('saving with nobody picked says what is missing', (tester) async {
    await pump(tester);
    repository.emit(const []);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('kid-routine-set-up-$kid-bedtime')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kid-routine-kid-$kid')));
    final save = find.byKey(const ValueKey('kid-routine-save'));
    await reveal(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repository.saved, isEmpty);
    await reveal(tester, find.byKey(const ValueKey('kid-routine-kid-$kid')));
    expect(
      find.text(KidRoutineCopy.missing(KidRoutineDraftProblem.noKids)),
      findsOneWidget,
    );
  });

  testWidgets('a routine shows its days, steps, time and stars, and opens', (
    tester,
  ) async {
    await pump(tester);
    repository.emit([KidRoutineFixtures.morning()]);
    await tester.pumpAndSettle();
    expect(find.text('School days · 3 steps · by 07:15'), findsOneWidget);
    expect(find.text(PointsCopy.starsCount(3)), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kid-routine-$kid-morning')));
    await tester.pumpAndSettle();
    expect(find.text(KidRoutineCopy.editRoutine), findsOneWidget);
    expect(find.text(KidRoutineCopy.partsCount(2)), findsOneWidget);
  });

  testWidgets('a quick add puts a step with its sticker on the routine', (
    tester,
  ) async {
    await pump(tester);
    repository.emit([KidRoutineFixtures.morning()]);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kid-routine-$kid-morning')));
    await tester.pumpAndSettle();
    final quick = find.byKey(const ValueKey('kid-routine-quick-make-bed'));
    await reveal(tester, quick);
    await tester.tap(quick);
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('kid-routine-save'));
    await reveal(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    final saved = repository.saved.single;
    expect(saved.id, 'morning');
    expect(saved.steps.last.title, 'Make bed');
    expect(saved.steps.last.picture, 'make-bed');
    expect(saved.steps.last.id, 's4');
  });

  testWidgets('a step opens, gains a thing to remember, and saves with it', (
    tester,
  ) async {
    await pump(tester);
    repository.emit([KidRoutineFixtures.morning()]);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kid-routine-$kid-morning')));
    await tester.pumpAndSettle();
    final step = find.byKey(const ValueKey('kid-routine-step-s2'));
    await reveal(tester, step);
    await tester.tap(step);
    await tester.pumpAndSettle();
    expect(find.text(KidRoutineCopy.editStep), findsOneWidget);

    final add = find.byKey(const ValueKey('kid-routine-part-add'));
    await reveal(tester, add);
    await tester.enterText(
      find.descendant(of: add, matching: find.byType(EditableText)),
      'Toothpaste',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final done = find.text(KidRoutineCopy.stepDone);
    await reveal(tester, done);
    await tester.tap(done);
    await tester.pumpAndSettle();

    final save = find.byKey(const ValueKey('kid-routine-save'));
    await reveal(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    final teeth = repository.saved.single.steps[1];
    expect(teeth.title, 'Brush teeth');
    expect(teeth.parts.single.text, 'Toothpaste');
    expect(teeth.parts.single.weekdays, isEmpty);
  });

  testWidgets('deleting asks first', (tester) async {
    await pump(tester);
    repository.emit([KidRoutineFixtures.morning()]);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kid-routine-$kid-morning')));
    await tester.pumpAndSettle();
    final delete = find.text(KidRoutineCopy.deleteRoutine);
    await reveal(tester, delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text(KidRoutineCopy.deleteConfirm), findsOneWidget);
    expect(repository.deleted, isEmpty);
    await tester.tap(find.text(KidRoutineCopy.deleteRoutine));
    await tester.pumpAndSettle();
    expect(repository.deleted, ['morning']);
  });

  testWidgets('a copy opens as a new routine for nobody yet', (tester) async {
    await pump(tester);
    repository.emit([KidRoutineFixtures.morning()]);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kid-routine-$kid-morning')));
    await tester.pumpAndSettle();
    final copy = find.text(KidRoutineCopy.makeCopy);
    await reveal(tester, copy);
    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(find.text(KidRoutineCopy.newRoutine), findsOneWidget);
    expect(find.text('Morning (copy)'), findsOneWidget);
  });

  testWidgets('somebody who may only look has no way to change anything', (
    tester,
  ) async {
    controller.dispose();
    controller = controllerFor(canEdit: false, setsStars: false);
    await pump(tester);
    repository.emit([KidRoutineFixtures.morning()]);
    await tester.pumpAndSettle();
    expect(
      find.text(KidRoutineCopy.setUp(KidRoutineSlot.bedtime)),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('kid-routine-$kid-morning')));
    await tester.pumpAndSettle();
    expect(find.text(KidRoutineCopy.editRoutine), findsNothing);
  });

  testWidgets('stars are offered to family only', (tester) async {
    controller.dispose();
    controller = controllerFor(setsStars: false);
    await pump(tester);
    repository.emit(const []);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('kid-routine-set-up-$kid-morning')),
    );
    await tester.pumpAndSettle();
    expect(find.text(KidRoutineCopy.stars), findsNothing);
  });

  testWidgets('a failed save is said in words', (tester) async {
    repository.saveFailure = const UnavailableFailure();
    await pump(tester);
    repository.emit(const []);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('kid-routine-set-up-$kid-morning')),
    );
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('kid-routine-save'));
    await reveal(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.failure(const UnavailableFailure())), findsOne);
  });

  group('dark, 200% text, 360 wide', () {
    Future<void> small(WidgetTester tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pump(tester, brightness: Brightness.dark, scale: 2);
      repository.emit([
        KidRoutineFixtures.morning(
          name: 'A school morning with swimming',
          kidIds: const [kid, 'm-kid-2'],
        ),
      ]);
      await tester.pumpAndSettle();
    }

    Future<void> openMorning(WidgetTester tester) async {
      final card = find.byKey(const ValueKey('kid-routine-$kid-morning'));
      await tester.scrollUntilVisible(card, 200);
      await reveal(tester, card);
      await tester.tap(card);
      await tester.pumpAndSettle();
    }

    testWidgets('the screen holds', (tester) async {
      await small(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the routine sheet holds, to its last button', (tester) async {
      await small(tester);
      await openMorning(tester);
      expect(tester.takeException(), isNull);
      await reveal(tester, find.text(KidRoutineCopy.deleteRoutine));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the step sheet holds, with a thing open', (tester) async {
      await small(tester);
      await openMorning(tester);
      final step = find.byKey(const ValueKey('kid-routine-step-s3'));
      await reveal(tester, step);
      await tester.tap(step);
      await tester.pumpAndSettle();
      final part = find.byKey(const ValueKey('kid-routine-part-p2'));
      await reveal(tester, part);
      await tester.tap(part);
      await tester.pumpAndSettle();
      expect(find.text(KidRoutineCopy.partDays), findsOneWidget);
      await reveal(tester, find.text(KidRoutineCopy.removeStep));
      expect(tester.takeException(), isNull);
    });
  });
}
