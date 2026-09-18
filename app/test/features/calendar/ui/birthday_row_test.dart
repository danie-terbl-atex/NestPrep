import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/calendar/ui/calendar_screen.dart';
import 'package:nestprep/features/household/model/birthday.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_calendar_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Friday 18 September 2026, where the household lives.
final _nowUtc = DateTime.utc(2026, 9, 18, 9);

/// A birthday on the week: what it says, and — the part that matters — what
/// tapping it does and does not do (birthdays ADR-0001).
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeCalendarRepository repository;
  late CalendarController controller;

  List<Member> parkers({Birthday? kidBirthday}) => [
    Fixtures.kid.copyWith(
      birthday: kidBirthday ?? Birthday(year: 2017, month: 9, day: 18),
    ),
    Fixtures.sam,
    Fixtures.thandi,
  ];

  setUp(() {
    repository = FakeCalendarRepository();
    controller = CalendarController(
      calendarRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => _nowUtc),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      householdMembers: parkers(),
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
  }) async {
    await pumpScreen(
      tester,
      CalendarScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<CalendarController>.value(value: controller),
      ],
      brightness: brightness,
      textScale: scale,
    );
    repository.emitEvents(const []);
    repository.emitExceptions(const []);
    await tester.pumpAndSettle();
  }

  testWidgets('says who it is and what age they turn', (tester) async {
    await pump(tester);

    expect(
      find.text(AppCopy.birthdayTurning(Fixtures.kid.displayName, 9)),
      findsOneWidget,
    );
    expect(
      find.textContaining(AppCopy.calendarBirthdayFromProfile),
      findsOneWidget,
      reason: 'it has to say where it comes from, or it reads as an event',
    );
  });

  testWidgets('says whose birthday it is when the year is not known', (
    tester,
  ) async {
    controller.showBirthdaysOf(
      parkers(kidBirthday: Birthday(month: 9, day: 18)),
    );
    await pump(tester);

    expect(
      find.text(AppCopy.birthdayOf(Fixtures.kid.displayName)),
      findsOneWidget,
    );
  });

  testWidgets('tapping it does not open the event sheet', (tester) async {
    await pump(tester);

    await tester.tap(
      find.text(AppCopy.birthdayTurning(Fixtures.kid.displayName, 9)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.calendarEditEvent),
      findsNothing,
      reason: 'a birthday is not an event, so there is nothing to edit here',
    );
    expect(
      find.text(AppCopy.calendarTitleLabel),
      findsNothing,
      reason: 'no event sheet opened at all',
    );
  });

  testWidgets('tapping it goes to the household, where it can be changed', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(
      find.text(AppCopy.birthdayTurning(Fixtures.kid.displayName, 9)),
    );
    await tester.pumpAndSettle();

    // `pumpScreen`'s router stands the household route up as a placeholder;
    // arriving there is the whole assertion (`FE-17`).
    expect(find.byType(Placeholder), findsOneWidget);
    expect(find.text(AppCopy.calendarTitle), findsNothing);
  });

  testWidgets('and the week is still there to come back to', (tester) async {
    await pump(tester);
    await tester.tap(
      find.text(AppCopy.birthdayTurning(Fixtures.kid.displayName, 9)),
    );
    await tester.pumpAndSettle();

    // It has to push, not replace. The header's household link was written
    // replacing once, and the system back button closed the app
    // (`household_navigation_test.dart`).
    final router = GoRouter.of(tester.element(find.byType(Placeholder)));
    expect(router.canPop(), isTrue);

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.calendarTitle), findsOneWidget);
  });

  testWidgets('a day with only a birthday is not an empty day', (tester) async {
    await pump(tester);
    expect(find.text(AppCopy.calendarEmptyBody), findsNothing);
  });

  testWidgets('holds at phone width in dark at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);

    expect(tester.takeException(), isNull);
    expect(
      find.text(AppCopy.birthdayTurning(Fixtures.kid.displayName, 9)),
      findsOneWidget,
    );
  });
}
