import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/calendar/model/calendar_view.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/calendar/ui/calendar_month_grid.dart';
import 'package:nestprep/features/calendar/ui/calendar_screen.dart';
import 'package:nestprep/features/calendar/ui/calendar_week_strip.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/features/household/ui/household_more_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/points_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../support/fake_calendar_repository.dart';
import '../support/fake_calendar_sync.dart';
import '../support/fake_household.dart';
import '../support/household_fixtures.dart';
import '../support/pump_screen.dart';

/// The calendar is a tab of its own again, and opens on the month
/// (design-system ADR-0017): More no longer offers it, it carries no way
/// back, the bar lights Calendar, and the month grid pages, picks a day and
/// hands over to the week strip.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeCalendarRepository calendar;
  late CalendarController controller;
  late FakeHouseholdRepository households;
  late HouseholdController household;

  setUp(() {
    calendar = FakeCalendarRepository();
    households = FakeHouseholdRepository();
    household = HouseholdController(
      householdRepository: households,
      householdDirectory: FakeHouseholdDirectory(),
      householdId: Fixtures.householdId,
      viewerUid: Fixtures.samUid,
    );
  });

  tearDown(() async {
    household.dispose();
    await calendar.close();
    await households.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    required HouseholdTab at,
    Size size = const Size(420, 1600),
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    // Made inside the test, so moving the window reopens its reads on the
    // test's clock and a pump lets them land.
    controller = CalendarController(
      calendarRepository: calendar,
      calendarSyncRepository: FakeCalendarSyncRepository(),
      householdClock: HouseholdClock(
        'Africa/Johannesburg',
        now: () => DateTime.utc(2026, 10, 22, 9),
      ),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      householdMembers: const [],
      initialView: CalendarView.month,
    );
    addTearDown(controller.dispose);
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpRouter(
      tester,
      router: GoRouter(
        initialLocation: HouseholdRoute.pathFor(Fixtures.householdId, at),
        routes: [
          GoRoute(
            path: '${HouseholdRoute.path}/${HouseholdTab.more.segment}',
            builder: (context, state) =>
                HouseholdMoreScreen(onSelectTab: (_) {}),
          ),
          GoRoute(
            path: '${HouseholdRoute.path}/${HouseholdTab.week.segment}',
            builder: (context, state) => CalendarScreen(onSelectTab: (_) {}),
          ),
        ],
      ),
      providers: [
        ChangeNotifierProvider<HouseholdController>.value(value: household),
        ChangeNotifierProvider<CalendarController>.value(value: controller),
      ],
      brightness: brightness,
      textScale: textScale,
    );
    households.emitHousehold(Fixtures.household());
    households.emitMembers([Fixtures.sam, Fixtures.thandi, Fixtures.kid]);
    await tester.pump();
    calendar
      ..emitEvents([
        HouseholdEvent(
          id: 'e1',
          title: 'Soccer',
          date: CalendarDate(2026, 10, 27),
          startMinute: 17 * 60,
          endMinute: 18 * 60,
          memberIds: const [Fixtures.samMemberId],
          createdBy: Fixtures.samMemberId,
        ),
      ])
      ..emitExceptions([]);
    await tester.pumpAndSettle();
  }

  /// A moved window opens its exceptions read again once the old one has
  /// cancelled — a real microtask, which the test's clock does not run — and
  /// holds its layout, pulsing, until the new read answers.
  Future<void> answer(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    calendar.emitExceptions([]);
    await tester.pumpAndSettle();
  }

  testWidgets('More no longer offers the calendar; the bar does', (
    tester,
  ) async {
    await pump(tester, at: HouseholdTab.more);
    expect(find.text(PointsCopy.screenTitle), findsOneWidget);
    expect(find.text(AppCopy.tabCalendar), findsOneWidget, reason: 'the bar');
    expect(find.text(AppCopy.tabFood), findsOneWidget, reason: 'the bar');
  });

  testWidgets('the calendar is a tab: no way back, and the bar lights it', (
    tester,
  ) async {
    await pump(tester, at: HouseholdTab.week);
    expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(
        find.descendant(
          of: find.byType(NestBottomBar),
          matching: find.bySemanticsLabel(AppCopy.tabCalendar),
        ),
      ),
      matchesSemantics(
        label: AppCopy.tabCalendar,
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('opens on the month, with the day that has something on '
      'saying so', (tester) async {
    await pump(tester, at: HouseholdTab.week);
    expect(find.byType(CalendarMonthGrid), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);

    final handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp(r'^Tue 27 October 2026, 1 thing on$')),
      findsOneWidget,
    );
    handle.dispose();

    await tester.tap(find.text('27'));
    await tester.pumpAndSettle();
    expect(controller.selectedDay, CalendarDate(2026, 10, 27));
    expect(find.text('Soccer'), findsOneWidget);
  });

  testWidgets('a day of the next month turns to that month', (tester) async {
    await pump(tester, at: HouseholdTab.week);
    // The grid's last row runs into November.
    await tester.tap(find.text('1').last);
    await answer(tester);
    expect(controller.month.first, CalendarDate(2026, 11, 1));
    expect(controller.selectedDay, CalendarDate(2026, 11, 1));
    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text(AppCopy.calendarThisMonth), findsOneWidget);
  });

  testWidgets('Week shows the strip around the chosen day', (tester) async {
    await pump(tester, at: HouseholdTab.week);
    await tester.tap(find.text('27'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.calendarWeek));
    await answer(tester);

    expect(find.byType(CalendarWeekStrip), findsOneWidget);
    expect(find.byType(CalendarMonthGrid), findsNothing);
    expect(controller.weekStart, CalendarDate(2026, 10, 26));
    expect(find.text('Soccer'), findsOneWidget);
  });

  testWidgets('the month fits a 360-wide phone at 200% text in dark', (
    tester,
  ) async {
    await pump(
      tester,
      at: HouseholdTab.week,
      size: const Size(360, 800),
      brightness: Brightness.dark,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text(AppCopy.calendarWeekFilter),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
  });
}
