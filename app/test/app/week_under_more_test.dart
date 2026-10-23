import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/calendar/ui/calendar_screen.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/features/household/ui/household_more_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/points_copy.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../support/fake_calendar_repository.dart';
import '../support/fake_calendar_sync.dart';
import '../support/fake_household.dart';
import '../support/household_fixtures.dart';
import '../support/pump_screen.dart';

/// The week moved off the bar to More (design-system ADR-0015): it is the
/// first place under *Plan the week*, it opens over More with a way back,
/// and while it is open the bar lights More (`FE-17`, `FE-13`).
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeCalendarRepository calendar;
  late CalendarController controller;
  late FakeHouseholdRepository households;
  late HouseholdController household;

  setUp(() {
    calendar = FakeCalendarRepository();
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
    );
    households = FakeHouseholdRepository();
    household = HouseholdController(
      householdRepository: households,
      householdDirectory: FakeHouseholdDirectory(),
      householdId: Fixtures.householdId,
      viewerUid: Fixtures.samUid,
    );
  });

  tearDown(() async {
    controller.dispose();
    household.dispose();
    await calendar.close();
    await households.close();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpRouter(
      tester,
      router: GoRouter(
        initialLocation: HouseholdRoute.pathFor(
          Fixtures.householdId,
          HouseholdTab.more,
        ),
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
    );
    households.emitHousehold(Fixtures.household());
    households.emitMembers([Fixtures.sam, Fixtures.thandi, Fixtures.kid]);
    await tester.pumpAndSettle();
  }

  testWidgets('More offers the week first under Plan the week', (tester) async {
    await pump(tester);
    final week = find.text(AppCopy.tabWeek).first;
    final stars = find.text(PointsCopy.screenTitle);
    expect(week, findsOneWidget);
    expect(
      tester.getTopLeft(week).dy,
      lessThanOrEqualTo(tester.getTopLeft(stars).dy),
    );
    expect(find.text(AppCopy.tabMeals), findsOneWidget, reason: 'the bar');
  });

  testWidgets('the week opens over More, lights More, and goes back', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text(MoreCopy.weekBody));
    // The week holds its layout, pulsing, until its listener answers.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    calendar
      ..emitEvents([])
      ..emitExceptions([]);
    await tester.pumpAndSettle();

    expect(find.byType(CalendarScreen), findsOneWidget);
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.bySemanticsLabel(MoreCopy.tab)),
      matchesSemantics(
        label: MoreCopy.tab,
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();

    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();
    expect(find.byType(HouseholdMoreScreen), findsOneWidget);
  });
}
