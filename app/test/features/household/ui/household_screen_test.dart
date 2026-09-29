import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/features/household/ui/household_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/kid_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_household.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// The screen an admin manages the household from — who is in it, who has
/// joined, and the three things that cannot be undone: removing somebody,
/// leaving, and handing out a code.
///
/// It was at one covered line out of eighty-two.
void main() {
  late FakeHouseholdRepository repository;
  late FakeHouseholdDirectory directory;
  late HouseholdController controller;

  setUp(() {
    repository = FakeHouseholdRepository();
    directory = FakeHouseholdDirectory();
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  /// Builds the controller for one viewer. [viewerUid] decides what the screen
  /// offers, because the household's map is what says who is an admin.
  void controllerFor(String viewerUid) {
    controller = HouseholdController(
      householdRepository: repository,
      householdDirectory: directory,
      householdId: Fixtures.householdId,
      viewerUid: viewerUid,
    );
  }

  Future<void> pump(
    WidgetTester tester, {
    String viewerUid = Fixtures.samUid,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) {
    controllerFor(viewerUid);
    return pumpScreen(
      tester,
      const HouseholdScreen(),
      providers: [
        ChangeNotifierProvider<HouseholdController>.value(value: controller),
      ],
      brightness: brightness,
      textScale: scale,
    );
  }

  Future<void> emit(
    WidgetTester tester, {
    List<Member>? members,
    Household? household,
  }) async {
    repository.emitHousehold(household ?? Fixtures.household());
    repository.emitMembers(
      members ?? [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    );
    await tester.pumpAndSettle();
  }

  group('the four states', () {
    testWidgets('holds the layout while it loads', (tester) async {
      await pump(tester);
      await tester.pump();
      expect(find.text(AppCopy.householdTitle), findsOneWidget);
      expect(find.byType(NestEmptyView), findsNothing);
    });

    testWidgets('a failed read offers a retry that re-reads', (tester) async {
      await pump(tester);
      repository.failHouseholdWith(const UnavailableFailure());
      await tester.pumpAndSettle();

      expect(find.text(AppCopy.retry), findsOneWidget);
      await tester.tap(find.text(AppCopy.retry));
      // `onRetry` hands back a Future nobody awaits, and it cancels two
      // subscriptions before making two more. Pumping frames cannot see that —
      // only letting real async run can. `pumpEventQueue` hangs here, because
      // the binding has its own pending work.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await emit(tester);

      expect(
        find.text('Sam Parent'),
        findsOneWidget,
        reason: 'retry re-read, it did not just clear the error',
      );
    });

    testWidgets('a household with nobody in it still offers the way in', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester, members: []);

      expect(find.text(AppCopy.householdEmptyTitle), findsOneWidget);
      expect(
        find.text(AppCopy.householdAddMember),
        findsWidgets,
        reason: 'an empty household is exactly when somebody is added',
      );
    });

    testWidgets('the people show, with their roles', (tester) async {
      await pump(tester);
      await emit(tester);

      for (final name in ['Sam Parent', 'Thandi Helper', 'Kid Parker']) {
        expect(find.text(name), findsOneWidget);
      }
    });
  });

  group('what an admin may do, and a helper may not', () {
    testWidgets('an admin is offered the way to add somebody', (tester) async {
      await pump(tester);
      await emit(tester);
      expect(find.byIcon(Icons.person_add_alt), findsOneWidget);
    });

    testWidgets('a helper is not', (tester) async {
      await pump(tester, viewerUid: Fixtures.thandiUid);
      await emit(tester);
      expect(find.byIcon(Icons.person_add_alt), findsNothing);
    });

    testWidgets('only an unclaimed profile can be invited', (tester) async {
      await pump(tester);
      await emit(tester);

      // Kid is the only unclaimed one of the three.
      expect(
        find.bySemanticsLabel(AppCopy.householdInvite),
        findsOneWidget,
        reason: 'Sam and Thandi have already joined',
      );
    });

    testWidgets('you are never offered the button that removes you', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester);

      // Thandi and Kid may be removed; Sam is the viewer.
      expect(find.bySemanticsLabel(AppCopy.householdRemove), findsNWidgets(2));
    });
  });

  group('the things that cannot be undone', () {
    testWidgets('removing somebody asks first, and takes no for an answer', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester);

      await tester.tap(find.bySemanticsLabel(AppCopy.householdRemove).first);
      await tester.pumpAndSettle();
      expect(find.text(AppCopy.householdRemoveConfirm), findsOneWidget);

      await tester.tap(find.text(AppCopy.householdCancel));
      await tester.pumpAndSettle();

      expect(
        directory.removed,
        isEmpty,
        reason: 'cancelling a removal must remove nobody',
      );
    });

    testWidgets('and goes ahead when it is confirmed', (tester) async {
      await pump(tester);
      await emit(tester);

      await tester.tap(find.bySemanticsLabel(AppCopy.householdRemove).first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(NestButton, AppCopy.householdRemove),
      );
      await tester.pumpAndSettle();

      expect(directory.removed, hasLength(1));
    });

    testWidgets('the last admin cannot leave, and is told why', (tester) async {
      await pump(tester);
      // Only Sam is an admin in the fixture household.
      await emit(tester);

      await tester.scrollUntilVisible(
        find.text(AppCopy.householdProblemLastAdmin),
        120,
      );
      expect(find.text(AppCopy.householdProblemLastAdmin), findsOneWidget);
      final leave = tester.widget<NestButton>(
        find.widgetWithText(NestButton, AppCopy.householdLeave),
      );
      expect(
        leave.onPressed,
        isNull,
        reason: 'a household with no admin is a household nobody can manage',
      );
    });

    testWidgets('somebody who is not the last admin may leave, after asking', (
      tester,
    ) async {
      await pump(tester, viewerUid: Fixtures.thandiUid);
      await emit(
        tester,
        household: const Household(
          id: Fixtures.householdId,
          name: 'The Parkers',
          timeZone: 'Africa/Johannesburg',
          members: {Fixtures.samUid: 'admin', Fixtures.thandiUid: 'admin'},
          createdBy: Fixtures.samUid,
        ),
      );

      await tester.scrollUntilVisible(
        find.widgetWithText(NestButton, AppCopy.householdLeave),
        120,
      );
      await tester.tap(find.widgetWithText(NestButton, AppCopy.householdLeave));
      await tester.pumpAndSettle();
      expect(find.text(AppCopy.householdLeaveConfirm), findsOneWidget);

      await tester.tap(
        find.widgetWithText(NestButton, AppCopy.householdLeave).last,
      );
      await tester.pumpAndSettle();

      expect(directory.left, [Fixtures.householdId]);
    });
  });

  testWidgets('a refused action becomes a banner, and can be dismissed', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester);
    directory.failWith = const PermissionDeniedFailure();

    await tester.tap(find.bySemanticsLabel(AppCopy.householdRemove).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NestButton, AppCopy.householdRemove));
    await tester.pumpAndSettle();

    expect(find.byType(NestBanner), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(NestBanner),
        matching: find.text(AppCopy.back),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NestBanner), findsNothing);
  });

  group('the household itself', () {
    Finder fieldLabelled(String label) => find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(NestTextField),
      ),
      matching: find.byType(TextField),
    );

    testWidgets('an admin is offered its settings', (tester) async {
      await pump(tester);
      await emit(tester);
      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('a helper is not', (tester) async {
      await pump(tester, viewerUid: Fixtures.thandiUid);
      await emit(tester);
      expect(
        find.byIcon(Icons.tune),
        findsNothing,
        reason: 'the rules refuse it, so the screen must not offer it',
      );
    });

    testWidgets('renaming it, and moving its time zone, is one write', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      await tester.enterText(
        fieldLabelled(AppCopy.householdNameLabel),
        'The Parker-Dlaminis',
      );
      await tester.enterText(
        fieldLabelled(AppCopy.householdTimeZoneLabel),
        'Europe/London',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NestButton, AppCopy.householdSave));
      await tester.pumpAndSettle();

      final saved = repository.renamed.single;
      expect(saved.name, 'The Parker-Dlaminis');
      expect(
        saved.timeZone,
        'Europe/London',
        reason: 'the zone is what every due date and all-day event means',
      );
    });

    testWidgets('changing nothing is not offered as a save', (tester) async {
      await pump(tester);
      await emit(tester);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      final save = tester.widget<NestButton>(
        find.widgetWithText(NestButton, AppCopy.householdSave),
      );
      expect(save.onPressed, isNull);
    });

    testWidgets('and an empty zone is refused before it is sent', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.enterText(fieldLabelled(AppCopy.householdTimeZoneLabel), '');
      await tester.pumpAndSettle();

      final save = tester.widget<NestButton>(
        find.widgetWithText(NestButton, AppCopy.householdSave),
      );
      expect(
        save.onPressed,
        isNull,
        reason: 'a household with no zone has no idea what day it is',
      );
    });
  });

  group('the way to where everybody is', () {
    testWidgets('is on this screen, and says what it is before it is tapped', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester);

      await tester.scrollUntilVisible(
        find.text(AppCopy.locationYoursBody),
        120,
      );
      expect(find.text(AppCopy.locationTitle), findsOneWidget);
      expect(
        find.text(AppCopy.locationYoursBody),
        findsOneWidget,
        reason:
            'that sharing is each person"s own is worth knowing before the '
            'tap, not after (live-location ADR-0002)',
      );
    });

    testWidgets('goes there, and pushes so that back comes back here', (
      tester,
    ) async {
      // Two failures in one test. The first is the one this app has had
      // twice: a capability finished in the model, the repository and the
      // rules, with the words already written, and no control anywhere that
      // opened it. The second is `go` where `push` was meant — identical
      // until somebody presses back and the app closes (`FE-17`).
      await pump(tester);
      await emit(tester);

      await tester.scrollUntilVisible(find.text(AppCopy.locationTitle), 120);
      await tester.ensureVisible(find.text(AppCopy.locationYoursBody));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppCopy.locationTitle));
      await tester.pumpAndSettle();
      expect(find.byType(Placeholder), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text(AppCopy.householdTitle), findsOneWidget);
    });

    testWidgets('is offered to a helper exactly as it is to an admin', (
      tester,
    ) async {
      // Nothing here is an admin action: every member controls their own
      // sharing and nobody else's (live-location ADR-0002).
      await pump(tester, viewerUid: Fixtures.thandiUid);
      await emit(tester);

      await tester.scrollUntilVisible(find.text(AppCopy.locationTitle), 120);
      expect(find.text(AppCopy.locationTitle), findsOneWidget);
    });
  });

  group('the way to kids\u2019 sign-in (accounts ADR-0003)', () {
    testWidgets('an admin is offered it, and it says what it is', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester);

      await tester.scrollUntilVisible(find.text(KidCopy.manageEntry), 200);
      expect(find.text(KidCopy.manageEntryBody), findsOneWidget);
    });

    testWidgets('it pushes, so back comes back here', (tester) async {
      await pump(tester);
      await emit(tester);

      await tester.scrollUntilVisible(find.text(KidCopy.manageEntry), 200);
      await tester.tap(find.text(KidCopy.manageEntry));
      await tester.pumpAndSettle();
      expect(find.byType(Placeholder), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(AppCopy.householdTitle), findsOneWidget);
    });

    testWidgets('a helper is not — only an admin can make a code', (
      tester,
    ) async {
      await pump(tester, viewerUid: Fixtures.thandiUid);
      await emit(tester);

      // Scrolled to the row that sits just below it, so "not found" means
      // not there rather than not built yet.
      await tester.scrollUntilVisible(find.text(AppCopy.locationTitle), 200);
      expect(find.text(KidCopy.manageEntry), findsNothing);
    });
  });

  testWidgets('it holds at phone width in dark at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await emit(tester);

    expect(tester.takeException(), isNull);
    // Scrolled through to the last group, so every row has been laid out at
    // this size, not only the ones that fit on the first screen.
    await tester.scrollUntilVisible(find.text('Thandi Helper'), 200);
    expect(tester.takeException(), isNull);
    expect(find.text('Thandi Helper'), findsOneWidget);
  });
}
