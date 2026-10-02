import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/family_roster.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/lunch_box/model/lunch_feedback.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/ui/lunch_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_harness.dart';
import '../../../support/pump_screen.dart';
import '../../../support/test_flags.dart';

void main() {
  late LunchHarness harness;

  late FeatureFlagsController flagsOff;

  setUp(() {
    harness = LunchHarness();
    flagsOff = testFlagsController(TestFlags.off);
  });
  tearDown(() async {
    flagsOff.dispose();
    await harness.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
    LunchHarness? using,
    bool viewOnly = false,
  }) async {
    // Tall enough that a whole day card and its thumbs are on screen.
    tester.view.physicalSize = const Size(420 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      LunchScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<FeatureFlagsController>.value(value: flagsOff),
        ...(using ?? harness).providers,
      ],
      view: viewOnly
          ? Fixtures.helperView(
              AccessGrant({
                HouseholdArea.lunch: AccessLevel.view,
                HouseholdArea.familyProfiles: AccessLevel.view,
              }),
            )
          : null,
      brightness: brightness,
      textScale: scale,
    );
  }

  Future<void> arrive(
    WidgetTester tester, {
    FamilyRoster? roster,
    Map<String, LunchPick> lwaziSlots = const {},
    Map<String, LunchFeedback> lwaziMarks = const {},
    LunchHarness? using,
  }) async {
    (using ?? harness).emit(
      roster: roster,
      plans: [
        LunchFixtures.plan(
          LunchFixtures.lwaziId,
          slots: lwaziSlots,
          feedback: lwaziMarks,
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  String key(int day, LunchSlot slot) => LunchFixtures.key(day, slot);

  testWidgets('holds the layout while it loads', (tester) async {
    await pump(tester);
    await tester.pump();
    expect(find.text(LunchCopy.title), findsOneWidget);
    expect(find.text(LunchCopy.fillWeek), findsNothing);
  });

  testWidgets('with no children, says where they are added and links there', (
    tester,
  ) async {
    await pump(tester);
    await arrive(
      tester,
      roster: FamilyRoster(
        members: [Fixtures.sam],
        profiles: const [],
        schools: const [],
      ),
    );
    expect(find.text(LunchCopy.noChildrenTitle), findsOneWidget);
    await tester.tap(find.text(LunchCopy.openFamily));
    await tester.pumpAndSettle();
    expect(find.byType(Placeholder), findsOneWidget);
  });

  testWidgets('the week is shared from the board (lunch-box ADR-0005)', (
    tester,
  ) async {
    await pump(tester);
    await arrive(
      tester,
      lwaziSlots: {key(1, LunchSlot.main): LunchPick.of(LunchFixtures.wrap)},
    );
    await tester.tap(find.text(LunchShareCopy.openShare));
    await tester.pumpAndSettle();
    expect(find.byType(Placeholder), findsOneWidget);
  });

  testWidgets('shows human copy and a retry when a read fails', (tester) async {
    await pump(tester);
    harness.repository.failItemsWith(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('opens on the first child, today’s box drawn, the week below', (
    tester,
  ) async {
    await pump(tester);
    await arrive(
      tester,
      lwaziSlots: {key(2, LunchSlot.main): LunchPick.of(LunchFixtures.wrap)},
    );
    expect(
      find.text(LunchCopy.dayFor('Today', 'Lwazi').toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('Chicken wrap'), findsWidgets);
    // The photo card is one sentence to a screen reader: whose day, and what
    // is packed.
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('for Lwazi. Chicken wrap')),
      findsOneWidget,
    );
    semantics.dispose();
    // Their school rule is said up front.
    expect(find.textContaining('school rule'), findsOneWidget);
  });

  testWidgets('a tap on an empty compartment offers the ranked library', (
    tester,
  ) async {
    await pump(tester);
    await arrive(tester);

    await tester.tap(find.text(LunchCopy.addToSlot(LunchSlot.main)).first);
    await tester.pumpAndSettle();

    expect(find.text(LunchCopy.suggestedFor('Lwazi')), findsOneWidget);
    expect(find.text(LunchCopy.notSafeFor('Lwazi')), findsOneWidget);

    // The unsafe one is shown, says why, and cannot be packed.
    await tester.ensureVisible(find.text('Peanut butter sandwich'));
    await tester.tap(find.text('Peanut butter sandwich'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(harness.repository.writtenPicks, isEmpty);

    await tester.tap(find.text('Chicken wrap'));
    await tester.pumpAndSettle();
    expect(
      harness.repository.writtenPicks.single.picks.values.single!.itemId,
      'wrap',
    );
  });

  testWidgets('fill the week packs the rest in one write', (tester) async {
    await pump(tester);
    await arrive(tester);
    await tester.tap(find.text(LunchCopy.fillWeek));
    await tester.pumpAndSettle();
    expect(
      harness.repository.writtenPicks.single.childId,
      LunchFixtures.lwaziId,
    );
    expect(find.textContaining('Packed 5 days'), findsOneWidget);
  });

  testWidgets('after school, a thumb says whether it came home eaten', (
    tester,
  ) async {
    await pump(tester);
    await arrive(
      tester,
      lwaziSlots: {key(1, LunchSlot.main): LunchPick.of(LunchFixtures.wrap)},
    );
    await tester.ensureVisible(find.text(LunchCopy.ateIt).first);
    await tester.tap(find.text(LunchCopy.ateIt).first);
    await tester.pumpAndSettle();
    final write = harness.repository.writtenFeedback.single;
    expect(write.day, 1);
    expect(write.feedback!.boxVerdict, LunchVerdict.ate);
  });

  testWidgets('a marked day says what came home, and can be changed', (
    tester,
  ) async {
    await pump(tester);
    await arrive(
      tester,
      lwaziSlots: {key(1, LunchSlot.main): LunchPick.of(LunchFixtures.wrap)},
      lwaziMarks: {'1': LunchFixtures.feedback(LunchVerdict.left)},
    );
    expect(find.text(LunchCopy.cameBackFull), findsOneWidget);
    await tester.ensureVisible(find.text(LunchCopy.changeMark));
    await tester.tap(find.text(LunchCopy.changeMark));
    await tester.pumpAndSettle();
    expect(find.text(LunchCopy.markItemsTitle), findsOneWidget);
    await tester.tap(find.text(LunchCopy.undoMark));
    await tester.pumpAndSettle();
    expect(harness.repository.writtenFeedback.single.feedback, isNull);
  });

  testWidgets('an unsafe box is named and marked, before it goes to school', (
    tester,
  ) async {
    await pump(tester);
    await arrive(
      tester,
      lwaziSlots: {
        key(3, LunchSlot.main): LunchPick.of(LunchFixtures.peanutButter),
      },
    );
    expect(find.text(LunchCopy.weekHasUnsafe), findsOneWidget);
    expect(find.text(LunchCopy.unsafeTag), findsOneWidget);
    expect(find.text(LunchCopy.allergicTo('peanuts')), findsWidgets);
  });

  testWidgets('each child has their own week', (tester) async {
    await pump(tester);
    await arrive(tester);
    await tester.tap(find.text('Ayanda'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(LunchCopy.dayFor('', 'Ayanda').toUpperCase()),
      findsOneWidget,
    );
    expect(harness.controller.selectedChildId, LunchFixtures.ayandaId);
  });

  testWidgets('somebody who may only look sees the week and no controls', (
    tester,
  ) async {
    final viewer = LunchHarness(canEdit: false);
    addTearDown(viewer.close);
    await pump(tester, using: viewer, viewOnly: true);
    await arrive(
      tester,
      using: viewer,
      lwaziSlots: {key(1, LunchSlot.main): LunchPick.of(LunchFixtures.wrap)},
    );
    expect(
      find.textContaining(LunchCopy.dayFor('', 'Lwazi').toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(LunchCopy.fillWeek), findsNothing);
    expect(find.text(LunchCopy.ateIt), findsNothing);
    expect(find.text(LunchCopy.openLibrary), findsNothing);
    expect(find.text(LunchShareCopy.openShare), findsNothing);
    await tester.tap(find.text('Chicken wrap').first);
    await tester.pumpAndSettle();
    expect(find.text(LunchCopy.suggestedFor('Lwazi')), findsNothing);
  });

  testWidgets('a refusal shows copy about the child, never a code', (
    tester,
  ) async {
    await pump(tester);
    await arrive(tester);
    await harness.controller.edit.pick(
      childId: LunchFixtures.lwaziId,
      isoWeekday: 2,
      item: LunchFixtures.peanutButter,
    );
    await tester.pumpAndSettle();
    expect(
      find.text(LunchCopy.problem(LunchProblem.unsafeForChild)),
      findsOneWidget,
    );
  });

  testWidgets('renders in dark and at 200% text without overflowing', (
    tester,
  ) async {
    await pump(tester, brightness: Brightness.dark, scale: 2);
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    await arrive(
      tester,
      lwaziSlots: {
        key(1, LunchSlot.main): LunchPick.of(LunchFixtures.peanutButter),
        key(1, LunchSlot.fruit): LunchPick.of(LunchFixtures.apple),
        key(2, LunchSlot.main): LunchPick.of(LunchFixtures.cheese),
      },
      lwaziMarks: {'1': LunchFixtures.feedback(LunchVerdict.ate)},
    );
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -1600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
