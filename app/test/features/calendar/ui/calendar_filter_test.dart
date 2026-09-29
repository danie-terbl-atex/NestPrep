import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/calendar/ui/calendar_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:nestprep/shared/ui/member_filter.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_calendar_repository.dart';
import '../../../support/fake_calendar_sync.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Narrowing the week to one person, and finding the way back to today.
///
/// `CalendarController` has carried `memberFilter`, `filterBy` and
/// `goToThisWeek` since the beginning, and the week model has always honoured
/// the filter. Nothing on the screen called any of them, so a week could be
/// paged away from and only paged back to, and the filter the phase scope
/// promised did not exist.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  final today = CalendarDate.parse('2026-09-18');

  late FakeCalendarRepository repository;
  late CalendarController controller;

  setUp(() {
    repository = FakeCalendarRepository();
    controller = CalendarController(
      calendarRepository: repository,
      calendarSyncRepository: FakeCalendarSyncRepository(),
      householdClock: HouseholdClock(
        'Africa/Johannesburg',
        now: () => DateTime.utc(2026, 9, 18, 6),
      ),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      householdMembers: const [],
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> pump(WidgetTester tester, {double scale = 1}) {
    // A phone, not the 800x600 the binding defaults to — that viewport is
    // shorter than any device this ships to.
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    return pumpScreen(
      tester,
      CalendarScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<CalendarController>.value(value: controller),
      ],
      textScale: scale,
    );
  }

  /// The filter is a horizontal list — on a phone the last chip is off the
  /// right-hand edge, which is the point of it scrolling.
  Future<void> tapInFilter(WidgetTester tester, String label) async {
    final target = find.descendant(
      of: find.byType(MemberFilter),
      matching: find.text(label),
    );
    final list = find.descendant(
      of: find.byType(MemberFilter),
      matching: find.byType(Scrollable),
    );

    // A horizontal `ListView` mounts only what is on screen, so a chip past
    // the edge is not in the tree at all — it cannot be scrolled *to*, only
    // scrolled *until it appears*. Which edge it is past depends on where the
    // list happens to be sitting, so both directions are tried.
    for (final step in [const Offset(-60, 0), const Offset(60, 0)]) {
      for (var i = 0; i < 12 && target.evaluate().isEmpty; i++) {
        await tester.drag(list, step);
        await tester.pumpAndSettle();
      }
      if (target.evaluate().isNotEmpty) break;
    }

    expect(target, findsOneWidget, reason: '"$label" is not in the filter');

    // Being in the tree is not being on screen: a list mounts a little either
    // side of the viewport, and a tap on a chip in that margin lands on
    // whatever *is* at that point. Same trap as a sheet, turned on its side.
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  HouseholdEvent event(String id, String title, List<String> members) =>
      HouseholdEvent(
        id: id,
        title: title,
        date: today,
        startMinute: 540,
        endMinute: 600,
        memberIds: members,
        createdBy: Fixtures.samMemberId,
      );

  Future<void> emit(WidgetTester tester) async {
    repository.emitEvents([
      event('e1', 'Kid — swimming', [Fixtures.kidMemberId]),
      event('e2', 'Thandi off early', [Fixtures.thandiMemberId]),
      event('e3', 'Parents evening', const []),
    ]);
    repository.emitExceptions([]);
    await tester.pumpAndSettle();
  }

  testWidgets('the week starts showing everybody', (tester) async {
    await pump(tester);
    await emit(tester);

    expect(find.text(AppCopy.calendarWeekFilter), findsOneWidget);
    for (final title in [
      'Kid — swimming',
      'Thandi off early',
      'Parents evening',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('choosing one person narrows it to theirs', (tester) async {
    await pump(tester);
    await emit(tester);

    await tapInFilter(tester, Fixtures.kid.displayName);

    expect(
      controller.memberFilter,
      Fixtures.kidMemberId,
      reason: 'the chip that was tapped decides what the week shows',
    );
    expect(find.text('Kid — swimming'), findsOneWidget);
    expect(find.text('Thandi off early'), findsNothing);
    expect(
      find.text('Parents evening'),
      findsOneWidget,
      reason: 'an event for everybody is for them too',
    );
  });

  testWidgets('and everybody brings the rest back', (tester) async {
    await pump(tester);
    await emit(tester);

    await tapInFilter(tester, Fixtures.kid.displayName);
    await tapInFilter(tester, AppCopy.calendarEveryone);

    expect(find.text('Thandi off early'), findsOneWidget);
  });

  group('finding the way back to today', () {
    testWidgets('is not offered while you are already on this week', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester);
      expect(find.text(AppCopy.calendarThisWeek), findsNothing);
    });

    testWidgets('appears once you have paged away, and returns', (
      tester,
    ) async {
      await pump(tester);
      await emit(tester);

      // Paging puts the agenda back on loading, and the skeleton pulses for
      // ever — `pumpAndSettle` waits for an animation that never ends, so the
      // frames here are counted rather than awaited.
      Future<void> page() async {
        await tester.tap(find.bySemanticsLabel(AppCopy.calendarNextWeek));
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        repository.emitEvents([]);
        repository.emitExceptions([]);
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      await page();
      await page();

      expect(find.text(AppCopy.calendarThisWeek), findsOneWidget);

      await tester.tap(find.text(AppCopy.calendarThisWeek));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      repository.emitEvents([]);
      repository.emitExceptions([]);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(controller.weekStart, today.weekStart);
      expect(
        find.text(AppCopy.calendarThisWeek),
        findsNothing,
        reason: 'there is nowhere left to go',
      );
    });
  });

  testWidgets('and all of it holds at 200% text', (tester) async {
    await pump(tester, scale: 2);
    await emit(tester);

    expect(tester.takeException(), isNull);
    expect(find.text(AppCopy.calendarWeekFilter), findsOneWidget);
  });
}
