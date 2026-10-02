import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/calendar/ui/calendar_screen.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/ui/household_places.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_calendar_repository.dart';
import '../../../support/fake_calendar_sync.dart';
import '../../../support/fake_feature_flag_source.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Calendar V2's two ways in (calendar ADR-0005, ADR-0006): each shows only
/// while its switch is on, and only to somebody the household lets use it —
/// a capability with no way in is not done, and a way in to a refusal is
/// worse (the vault lessons on both).
void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('snap a school letter, from the week', () {
    late FakeCalendarRepository repository;
    late CalendarController controller;

    setUp(() {
      repository = FakeCalendarRepository();
      controller = CalendarController(
        calendarRepository: repository,
        calendarSyncRepository: FakeCalendarSyncRepository(),
        householdClock: HouseholdClock('Africa/Johannesburg'),
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
        householdMembers: const [],
      );
    });

    tearDown(() async {
      controller.dispose();
      await repository.close();
    });

    Future<void> pump(
      WidgetTester tester, {
      bool flagsOn = true,
      HouseholdView? view,
    }) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => CalendarScreen(onSelectTab: (_) {}),
          ),
          GoRoute(
            path: '/households/:householdId/letter',
            builder: (context, state) =>
                const Text('letter screen', textDirection: TextDirection.ltr),
          ),
        ],
      );
      await pumpRouter(
        tester,
        router: router,
        view: view,
        providers: [
          ChangeNotifierProvider<CalendarController>.value(value: controller),
          featureFlagsProvider(defaultOn: flagsOn),
        ],
      );
      await tester.pump();
    }

    testWidgets('is offered to a parent, and opens the letter screen', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.bySemanticsLabel(SchoolLetterCopy.openFromWeek));
      await tester.pumpAndSettle();
      expect(find.text('letter screen'), findsOneWidget);
    });

    testWidgets('is not offered while its switch is off', (tester) async {
      await pump(tester, flagsOn: false);
      expect(
        find.bySemanticsLabel(SchoolLetterCopy.openFromWeek),
        findsNothing,
      );
    });

    testWidgets('is not offered to somebody who may only look at the week', (
      tester,
    ) async {
      await pump(tester, view: Fixtures.helperView(AccessDefaults.helper));
      expect(
        find.bySemanticsLabel(SchoolLetterCopy.openFromWeek),
        findsNothing,
      );
    });
  });

  group('the shared week, from More', () {
    Future<void> pump(
      WidgetTester tester, {
      bool flagsOn = true,
      HouseholdView? view,
    }) async {
      final household = view ?? Fixtures.view();
      await pumpScreen(
        tester,
        Scaffold(
          body: SingleChildScrollView(child: HouseholdPlaces(view: household)),
        ),
        view: household,
        providers: [featureFlagsProvider(defaultOn: flagsOn)],
      );
      await tester.pump();
    }

    testWidgets('is offered to the family', (tester) async {
      await pump(tester);
      expect(find.text(MentalLoadCopy.openFromHousehold), findsOneWidget);
    });

    testWidgets('is not offered while its switch is off', (tester) async {
      await pump(tester, flagsOn: false);
      expect(find.text(MentalLoadCopy.openFromHousehold), findsNothing);
    });

    testWidgets('is not offered to a helper — it is about the parents', (
      tester,
    ) async {
      await pump(tester, view: Fixtures.helperView(AccessDefaults.helper));
      expect(find.text(MentalLoadCopy.openFromHousehold), findsNothing);
    });

    test('the two switches are separate flags', () {
      expect(
        FeatureFlag.snapSchoolLetter.field,
        isNot(FeatureFlag.mentalLoadView.field),
      );
    });
  });
}
