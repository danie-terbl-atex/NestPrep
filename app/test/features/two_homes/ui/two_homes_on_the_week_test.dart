import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/calendar/ui/calendar_screen.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/ui/household_places.dart';
import 'package:nestprep/features/two_homes/model/co_parent_link.dart';
import 'package:nestprep/features/two_homes/state/custody_calendar.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_calendar_repository.dart';
import '../../../support/fake_calendar_sync.dart';
import '../../../support/fake_feature_flag_source.dart';
import '../../../support/fake_two_homes.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/outside_the_bar.dart';
import '../../../support/pump_two_homes.dart';
import '../../../support/two_homes_model_fixtures.dart';

/// Two homes where the household meets it every day (household ADR-0004):
/// the linked child's all-day band on the week, in the colour of the home
/// they are with, and the way in from the household screen — both behind the
/// `coParenting` flag.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('on the week', () {
    late FakeCalendarRepository calendar;
    late FakeTwoHomesRepository twoHomes;
    late CalendarController controller;

    setUp(() {
      calendar = FakeCalendarRepository();
      twoHomes = FakeTwoHomesRepository();
      controller = CalendarController(
        calendarRepository: calendar,
        calendarSyncRepository: FakeCalendarSyncRepository(),
        // Friday 2 October, the day Sam goes back to Mum's home.
        householdClock: HouseholdClock(
          'Africa/Johannesburg',
          now: () => DateTime.utc(2026, 10, 2, 9),
        ),
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
        householdMembers: const [],
      );
    });

    tearDown(() async {
      controller.dispose();
      await calendar.close();
      await twoHomes.close();
    });

    Future<void> open(
      WidgetTester tester, {
      List<CoParentLink>? links,
      bool withBands = true,
      Brightness brightness = Brightness.light,
      double textScale = 1,
      bool narrow = false,
    }) async {
      await pumpTwoHomes(
        tester,
        CalendarScreen(onSelectTab: (_) {}),
        brightness: brightness,
        textScale: textScale,
        narrow: narrow,
        providers: [
          ChangeNotifierProvider<CalendarController>.value(value: controller),
          if (withBands)
            ChangeNotifierProvider(
              create: (_) => CustodyCalendar(
                twoHomesRepository: twoHomes,
                householdId: Fixtures.householdId,
              ),
            ),
        ],
      );
      calendar
        ..emitEvents(const [])
        ..emitExceptions(const []);
      if (links != null) twoHomes.links.add(links);
      await tester.pumpAndSettle();
    }

    testWidgets('a handover day says where the child goes', (tester) async {
      await open(tester, links: [aLink()]);
      expect(
        find.text(TwoHomesCopy.bandHandover('Kid Parker', 'Mum’s home')),
        findsOneWidget,
      );
      expect(
        find.textContaining(TwoHomesCopy.handoverAt('17:00')),
        findsOneWidget,
      );
    });

    testWidgets('any other day says whose home it is, and opens the link', (
      tester,
    ) async {
      await open(tester, links: [aLink()]);
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Sat 3$')));
      await tester.pumpAndSettle();
      expect(
        find.text(TwoHomesCopy.bandWith('Kid Parker', 'Mum’s home')),
        findsOneWidget,
      );
      await tester.tap(
        find.text(TwoHomesCopy.bandWith('Kid Parker', 'Mum’s home')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('landed on /households/h1/two-homes/links/link-sam'),
        findsOneWidget,
      );
    });

    testWidgets('a link that is not active draws nothing', (tester) async {
      await open(tester, links: [aLink(status: LinkStatus.pending)]);
      expect(find.textContaining(TwoHomesCopy.bandFromTwoHomes), findsNothing);
      expect(find.text(AppCopy.calendarEmptyBody), findsOneWidget);
    });

    testWidgets('with two homes off, the week has no bands at all', (
      tester,
    ) async {
      await open(tester, withBands: false);
      expect(find.textContaining(TwoHomesCopy.bandFromTwoHomes), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a read that fails is a quiet line with a retry', (
      tester,
    ) async {
      await open(tester);
      twoHomes.links.addError(const UnavailableFailure());
      await tester.pumpAndSettle();
      expect(find.text(AppCopy.retry), findsOneWidget);
      expect(textOutsideTheBar(AppCopy.calendarTitle), findsOneWidget);
    });

    testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
      await open(
        tester,
        links: [
          aLink(),
          aLink().copyWith(id: 'link-2'),
        ],
        narrow: true,
        brightness: Brightness.dark,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('the way in from the household screen', () {
    Future<void> open(
      WidgetTester tester, {
      HouseholdView? view,
      bool flagsOn = true,
    }) async {
      final household = view ?? Fixtures.view();
      await pumpTwoHomes(
        tester,
        Scaffold(
          body: SingleChildScrollView(child: HouseholdPlaces(view: household)),
        ),
        view: household,
        providers: [featureFlagsProvider(defaultOn: flagsOn)],
      );
      await tester.pumpAndSettle();
    }

    testWidgets('is there for family while the flag is on, and opens', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text(TwoHomesCopy.openFromHousehold));
      await tester.pumpAndSettle();
      expect(find.text('landed on /households/h1/two-homes'), findsOneWidget);
    });

    testWidgets('is gone with the flag off', (tester) async {
      await open(tester, flagsOn: false);
      expect(find.text(TwoHomesCopy.openFromHousehold), findsNothing);
    });

    testWidgets('is not offered to a helper, who meets it on the week', (
      tester,
    ) async {
      await open(
        tester,
        view: Fixtures.helperView(AccessGrant.uniform(AccessLevel.edit)),
      );
      expect(find.text(TwoHomesCopy.openFromHousehold), findsNothing);
    });
  });
}
