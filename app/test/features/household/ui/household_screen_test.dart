import 'dart:async';

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

import '../../../support/fake_family_profiles.dart';
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
      childProfileDirectory: FakeFamilyProfileRepository(),
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
      expect(find.byIcon(LucideIcons.userPlus), findsOneWidget);
    });

    testWidgets('a helper is not', (tester) async {
      await pump(tester, viewerUid: Fixtures.thandiUid);
      await emit(tester);
      expect(find.byIcon(LucideIcons.userPlus), findsNothing);
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

    testWidgets('says it is removing while the server works, then that it is '
        'done', (tester) async {
      await pump(tester);
      await emit(tester);
      directory.gate = Completer<void>();

      await tester.tap(find.bySemanticsLabel(AppCopy.householdRemove).first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(NestButton, AppCopy.householdRemove),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(AppCopy.householdRemoving), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final others = tester.widgetList<NestIconButton>(
        find.byType(NestIconButton),
      );
      expect(
        others
            .where((button) => button.label == AppCopy.householdRemove)
            .every((button) => button.onPressed == null),
        isTrue,
        reason: 'a second removal would be refused without a word',
      );

      directory.release();
      repository.emitMembers([Fixtures.sam, Fixtures.thandi]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(AppCopy.householdRemoving), findsNothing);
      expect(
        find.text(AppCopy.householdRemoved(Fixtures.kid.displayName)),
        findsOneWidget,
      );
    });

    testWidgets('a refused removal keeps the row and says why', (tester) async {
      await pump(tester);
      await emit(tester);
      directory.failWith = const PermissionDeniedFailure();

      await tester.tap(find.bySemanticsLabel(AppCopy.householdRemove).first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(NestButton, AppCopy.householdRemove),
      );
      await tester.pumpAndSettle();

      expect(find.text(Fixtures.kid.displayName), findsOneWidget);
      expect(find.text(AppCopy.householdRemoving), findsNothing);
      expect(find.byType(NestBanner), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('the last admin cannot leave while another parent is in', (
      tester,
    ) async {
      await pump(tester);
      // Sam is the only admin; Thandi is a parent who could take it over.
      await emit(
        tester,
        household: const Household(
          id: Fixtures.householdId,
          name: 'The Parkers',
          timeZone: 'Africa/Johannesburg',
          members: {Fixtures.samUid: 'admin', Fixtures.thandiUid: 'parent'},
          createdBy: Fixtures.samUid,
        ),
      );

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
      expect(
        find.text(CloseHouseholdCopy.entry),
        findsNothing,
        reason: 'with another parent in it, the household has a way to go on',
      );
    });

    testWidgets('the only grown-up is offered Close household instead', (
      tester,
    ) async {
      await pump(tester);
      // Sam is the only admin, and the only other account is a helper.
      await emit(tester);

      await tester.scrollUntilVisible(
        find.text(CloseHouseholdCopy.entryHint),
        120,
      );
      expect(find.text(AppCopy.householdLeave), findsNothing);
      expect(find.text(AppCopy.householdProblemLastAdmin), findsNothing);

      await tester.tap(
        find.widgetWithText(NestButton, CloseHouseholdCopy.entry),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Placeholder), findsOneWidget);
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
      expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);
    });

    testWidgets('a helper is not', (tester) async {
      await pump(tester, viewerUid: Fixtures.thandiUid);
      await emit(tester);
      expect(
        find.byIcon(LucideIcons.slidersHorizontal),
        findsNothing,
        reason: 'the rules refuse it, so the screen must not offer it',
      );
    });

    testWidgets('renaming it, and moving its time zone, is one write', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester);

      await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
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

      await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
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

      await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
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

      // Scrolled to the last control on the screen, so "not found" means
      // not there rather than not built yet.
      await tester.scrollUntilVisible(find.text(AppCopy.householdLeave), 200);
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
