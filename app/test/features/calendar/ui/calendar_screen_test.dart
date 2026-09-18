import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/calendar/ui/calendar_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_calendar_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

final _nowUtc = DateTime.utc(2026, 9, 18, 9);

HouseholdEvent event({
  String id = 'e1',
  String title = 'School run',
  String on = '2026-09-18',
  int? startMinute = 450,
  RecurrenceRule? recurrence,
}) => HouseholdEvent(
  id: id,
  title: title,
  date: CalendarDate.parse(on),
  startMinute: startMinute,
  endMinute: startMinute == null ? null : startMinute + 60,
  recurrence: recurrence,
  createdBy: Fixtures.samMemberId,
);

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeCalendarRepository repository;
  late CalendarController controller;

  setUp(() {
    repository = FakeCalendarRepository();
    controller = CalendarController(
      calendarRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => _nowUtc),
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
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpScreen(
    tester,
    CalendarScreen(onSelectTab: (_) {}),
    providers: [
      ChangeNotifierProvider<CalendarController>.value(value: controller),
    ],
    brightness: brightness,
    textScale: scale,
  );

  Future<void> emit(
    WidgetTester tester, {
    List<HouseholdEvent> events = const [],
  }) async {
    repository.emitEvents(events);
    repository.emitExceptions([]);
    await tester.pumpAndSettle();
  }

  testWidgets('holds the layout while it loads', (tester) async {
    await pump(tester);
    await tester.pump();
    expect(find.text(AppCopy.calendarTitle), findsOneWidget);
  });

  testWidgets('says what to do next on a day with nothing on it', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester);
    expect(find.text(AppCopy.calendarEmptyBody), findsOneWidget);
    // Exactly one call to action: the screen's own button.
    expect(find.text(AppCopy.calendarAddEvent), findsOneWidget);
  });

  testWidgets('shows human copy and a retry when the read fails', (
    tester,
  ) async {
    await pump(tester);
    repository.failEventsWith(const UnavailableFailure());
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('shows the chosen day"s agenda with its time', (tester) async {
    await pump(tester);
    await emit(tester, events: [event()]);

    expect(find.text('School run'), findsOneWidget);
    expect(find.textContaining('07:30'), findsOneWidget);
  });

  testWidgets('an all-day event says so instead of a time', (tester) async {
    await pump(tester);
    await emit(tester, events: [event(title: 'Birthday', startMinute: null)]);

    expect(find.textContaining(AppCopy.calendarAllDay), findsWidgets);
  });

  testWidgets('tapping another day shows that day', (tester) async {
    await pump(tester);
    await emit(
      tester,
      events: [
        event(),
        event(id: 'e2', title: 'Swimming', on: '2026-09-19'),
      ],
    );
    expect(find.text('School run'), findsOneWidget);
    expect(find.text('Swimming'), findsNothing);

    // Saturday the 19th sits sixth in the strip.
    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();

    expect(find.text('Swimming'), findsOneWidget);
    expect(find.text('School run'), findsNothing);
  });

  testWidgets('moving to the next week shows its dates', (tester) async {
    await pump(tester);
    await emit(tester);

    await tester.tap(find.bySemanticsLabel(AppCopy.calendarNextWeek));
    // The agenda shows its loading skeleton, which animates forever — so pump
    // frames rather than settling, and let the reopened read answer.
    await tester.pump();
    await tester.pump();
    repository.emitExceptions([]);
    await tester.pump();
    await tester.pump();

    expect(controller.weekStart.iso, '2026-09-21');
    expect(find.text('21'), findsOneWidget);
  });

  testWidgets('the phone width has no horizontal scroll at 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await emit(tester, events: [event(title: 'Swimming lessons at the pool')]);

    expect(tester.takeException(), isNull);
    expect(find.text('Swimming lessons at the pool'), findsOneWidget);
  });
}
