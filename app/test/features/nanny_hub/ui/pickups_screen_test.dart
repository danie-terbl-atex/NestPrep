import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/app/nanny_hub_route.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/data/photo_picker.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_change.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_collector.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_drafts.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_person.dart';
import 'package:nestprep/features/nanny_hub/model/school_run.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/nanny_pickup_fixtures.dart';
import '../../../support/pump_nanny_hub.dart';
import '../../../support/test_flags.dart';

/// The school run and who may collect (nanny-hub ADR-0005): today first, the
/// people, the week and the changed days — family edits, everybody reads.
void main() {
  late NannyFakes fakes;

  setUp(() => fakes = NannyFakes());
  tearDown(() => fakes.close());

  Future<void> open(
    WidgetTester tester, {
    HouseholdView? view,
    List<PickupPerson> people = const [],
    List<SchoolRun> runs = const [],
    List<PickupChange> changes = const [],
    bool answer = true,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.pickupsPathFor(Fixtures.householdId),
      view: view,
      brightness: brightness,
      textScale: textScale,
    );
    fakes.answerAFullHub();
    if (answer) {
      fakes.pickups.emitAll(
        peopleList: people,
        runList: runs,
        changeList: changes,
      );
      await tester.pumpAndSettle();
    } else {
      // The skeleton breathes while it waits, so time never settles.
      await tester.pump();
    }
  }

  void tallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('the four states', () {
    testWidgets('waits for the pickups as well as the hub', (tester) async {
      await open(tester, answer: false);
      expect(find.text(NannyPickupCopy.today), findsNothing);
      fakes.pickups.emitAll();
      await tester.pumpAndSettle();
      expect(find.text(NannyPickupCopy.today), findsOneWidget);
    });

    testWidgets('a failed read says so in words, with a retry', (tester) async {
      await open(tester, answer: false);
      fakes.pickups.people.addError(const UnavailableFailure());
      await tester.pumpAndSettle();
      expect(
        find.text(AppCopy.failure(const UnavailableFailure())),
        findsOneWidget,
      );
      await tester.tap(find.text(AppCopy.retry));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      fakes.answerAFullHub();
      fakes.pickups.emitAll();
      await tester.pumpAndSettle();
      expect(find.text(NannyPickupCopy.today), findsOneWidget);
    });

    testWidgets('empty: a parent is told what to add, beside the control', (
      tester,
    ) async {
      tallScreen(tester);
      await open(tester);
      expect(find.text(NannyPickupCopy.noRunToday), findsOneWidget);
      expect(find.text(NannyPickupCopy.addPersonHint), findsOneWidget);
      expect(find.byTooltip(NannyPickupCopy.addPerson), findsOneWidget);
      expect(
        find.text(NannyPickupCopy.nobodyListed('Kid Parker')),
        findsOneWidget,
      );
      expect(find.text(NannyPickupCopy.noChanges), findsOneWidget);
      expect(find.byTooltip(NannyPickupCopy.addChange), findsOneWidget);
    });

    testWidgets('success: today names who collects, when and where', (
      tester,
    ) async {
      tallScreen(tester);
      await open(
        tester,
        people: [PickupFixtures.gogo, PickupFixtures.thabo],
        runs: [PickupFixtures.todaysRun],
      );
      expect(find.text('Gogo Dlamini'), findsWidgets);
      expect(find.textContaining('14:30'), findsWidgets);
      expect(find.textContaining('Oakwood, side gate'), findsWidgets);
      expect(find.text(NannyPickupCopy.changedToday), findsNothing);
    });
  });

  testWidgets('a change for today wins over the week, and is marked', (
    tester,
  ) async {
    tallScreen(tester);
    await open(
      tester,
      people: [PickupFixtures.gogo],
      runs: [PickupFixtures.todaysRun],
      changes: [PickupFixtures.nomsaToday],
    );
    expect(find.text(NannyPickupCopy.changedToday), findsOneWidget);
    expect(find.text('Nomsa Carer'), findsWidgets);
  });

  testWidgets('the door check is one tap from today', (tester) async {
    tallScreen(tester);
    await open(tester, people: [PickupFixtures.gogo]);
    await tester.tap(find.text(NannyPickupCopy.checkDoor));
    await tester.pumpAndSettle();
    expect(find.text(NannyPickupCopy.checkTitle), findsOneWidget);
  });

  group('a parent', () {
    testWidgets('adds a person with a photo, stored before the person', (
      tester,
    ) async {
      tallScreen(tester);
      fakes.picker.next = Uint8List.fromList(
        img.encodeJpg(img.Image(width: 40, height: 30)),
      );
      await open(tester);
      await tester.tap(find.byTooltip(NannyPickupCopy.addPerson));
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyCopy.takePhoto));
      await tester.pumpAndSettle();
      await tester.enterText(
        fieldLabelled(NannyPickupCopy.name),
        ' Thandi Mokoena ',
      );
      await tester.enterText(
        fieldLabelled(NannyPickupCopy.relationship),
        'Aunt',
      );
      await tester.enterText(
        fieldLabelled(NannyPickupCopy.idNote),
        'Red Toyota',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyCopy.save));
      // Compression runs in a background isolate, which only real time moves.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();

      expect(fakes.picker.asked, [PhotoSource.camera]);
      final (method, arguments) = fakes.pickups.writes.single;
      expect(method, 'addPerson');
      final draft = arguments['draft']! as PickupPersonDraft;
      expect(draft.name, 'Thandi Mokoena');
      expect(draft.childIds, {Fixtures.kidMemberId});
      final stored = fakes.photos.objects[arguments['photoId']]!;
      expect(stored.sublist(0, 2), [0xFF, 0xD8]);
    });

    testWidgets('cannot save a person with a number that has letters', (
      tester,
    ) async {
      tallScreen(tester);
      await open(tester);
      await tester.tap(find.byTooltip(NannyPickupCopy.addPerson));
      await tester.pumpAndSettle();
      await tester.enterText(fieldLabelled(NannyPickupCopy.name), 'Thabo');
      await tester.enterText(
        fieldLabelled(NannyPickupCopy.relationship),
        'Uncle',
      );
      await tester.enterText(fieldLabelled(NannyPickupCopy.phone), 'call me');
      await tester.pumpAndSettle();
      expect(find.text(NannyPickupCopy.phoneNotValid), findsOneWidget);
      await tester.tap(find.text(NannyCopy.save));
      await tester.pumpAndSettle();
      expect(fakes.pickups.writes, isEmpty);
    });

    testWidgets('sets who collects on a weekday, from the listed people', (
      tester,
    ) async {
      tallScreen(tester);
      await open(tester, people: [PickupFixtures.gogo]);
      await scrollTo(tester, find.text(NannyPickupCopy.weekdayName(3)));
      await tester.tap(find.text(NannyPickupCopy.weekdayName(3)));
      await tester.pumpAndSettle();
      expect(find.text('Thandi Helper'), findsOneWidget);
      await tester.tap(find.text('Gogo Dlamini').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyCopy.save));
      await tester.pumpAndSettle();
      final (method, arguments) = fakes.pickups.writes.single;
      expect(method, 'saveRun');
      final draft = arguments['draft']! as SchoolRunDraft;
      expect(draft.weekday, 3);
      expect(draft.collector, const CollectedByPerson('p-gogo'));
    });

    testWidgets('adds a day nobody collects', (tester) async {
      tallScreen(tester);
      await open(tester, people: [PickupFixtures.gogo]);
      await scrollTo(tester, find.byTooltip(NannyPickupCopy.addChange));
      await tester.tap(find.byTooltip(NannyPickupCopy.addChange));
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyPickupCopy.nobodyCollects));
      await tester.enterText(
        fieldLabelled(NannyPickupCopy.note),
        ' No school ',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyCopy.save));
      await tester.pumpAndSettle();
      final (method, arguments) = fakes.pickups.writes.single;
      expect(method, 'saveChange');
      final draft = arguments['draft']! as PickupChangeDraft;
      expect(draft.collector, const NobodyCollects());
      expect(draft.date, PickupFixtures.today);
      expect(draft.note, 'No school');
    });

    testWidgets('a refused change is a banner in words', (tester) async {
      tallScreen(tester);
      fakes.pickups.failWritesWith = const PermissionDeniedFailure();
      await open(tester, people: [PickupFixtures.gogo]);
      await tester.tap(find.text(NannyPickupCopy.weekdayName(1)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gogo Dlamini').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(NannyCopy.save));
      await tester.pumpAndSettle();
      expect(
        find.text(AppCopy.failure(const PermissionDeniedFailure())),
        findsOneWidget,
      );
    });
  });

  testWidgets('a carer reads everything and is offered no change', (
    tester,
  ) async {
    tallScreen(tester);
    await open(
      tester,
      view: NannyFixtures.carerView(),
      people: [PickupFixtures.gogo],
      runs: [PickupFixtures.todaysRun],
    );
    expect(find.text('Gogo Dlamini'), findsWidgets);
    expect(find.byTooltip(NannyPickupCopy.addPerson), findsNothing);
    expect(find.byTooltip(NannyPickupCopy.addChange), findsNothing);
    expect(find.text(NannyPickupCopy.notSet), findsNothing);
    await tester.tap(find.text('Gogo Dlamini').last);
    await tester.pumpAndSettle();
    expect(find.text(NannyPickupCopy.editPerson), findsNothing);
  });

  group('the hub row', () {
    testWidgets('is there while the flag is on', (tester) async {
      tallScreen(tester);
      await pumpNannyHub(tester, fakes);
      fakes.answerAFullHub();
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text(NannyPickupCopy.place));
      await tester.tap(find.text(NannyPickupCopy.place));
      await tester.pump();
      fakes.pickups.emitAll();
      await tester.pumpAndSettle();
      expect(find.text(NannyPickupCopy.today), findsOneWidget);
    });

    testWidgets('is gone when the flag is off', (tester) async {
      tallScreen(tester);
      await pumpNannyHub(tester, fakes, flags: TestFlags.off);
      fakes.answerAFullHub();
      await tester.pumpAndSettle();
      expect(find.text(NannyCopy.checklists), findsOneWidget);
      expect(find.text(NannyPickupCopy.place), findsNothing);
    });
  });

  testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await open(
      tester,
      people: [PickupFixtures.gogo, PickupFixtures.thabo],
      runs: [PickupFixtures.todaysRun],
      changes: [PickupFixtures.nomsaToday],
      brightness: Brightness.dark,
      textScale: 2,
    );
    await scrollTo(tester, find.text(NannyPickupCopy.changes));
    expect(tester.takeException(), isNull);
  });
}
