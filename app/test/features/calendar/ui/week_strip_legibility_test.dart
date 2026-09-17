import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/calendar/ui/calendar_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_calendar_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Seven day names across a phone, at the largest text a phone offers.
///
/// Nothing clipped and nothing overflowed even before this test existed — the
/// names simply met in the middle and read as one word, *MonTueWed*. An
/// overflow test cannot see that, because there is no overflow: the `FittedBox`
/// shrinks the type until it fits, however little room it is given. So this
/// measures the gap instead (`FE-13`).
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeCalendarRepository repository;
  late CalendarController controller;

  setUp(() {
    repository = FakeCalendarRepository();
    controller = CalendarController(
      calendarRepository: repository,
      householdClock: HouseholdClock(
        'Africa/Johannesburg',
        now: () => DateTime.utc(2026, 9, 18, 9),
      ),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> pump(WidgetTester tester, double scale) async {
    // A phone, not the 800x600 the test binding defaults to: at 200% text the
    // agenda's empty state does not fit a viewport that short, and that has
    // nothing to do with the strip.
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpScreen(
      tester,
      CalendarScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<CalendarController>.value(value: controller),
      ],
      textScale: scale,
    );
    repository.emitEvents([]);
    repository.emitExceptions([]);
    await tester.pumpAndSettle();
  }

  /// The seven day-name labels, left to right.
  List<Rect> weekdayRects(WidgetTester tester) => [
    for (final name in AppCopy.weekdayNames)
      tester.getRect(find.text(name).first),
  ];

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('the seven day names stay apart at ${scale}x text', (
      tester,
    ) async {
      await pump(tester, scale);

      final rects = weekdayRects(tester);
      expect(rects, hasLength(7));

      for (var i = 0; i < rects.length - 1; i++) {
        final gap = rects[i + 1].left - rects[i].right;
        expect(
          gap,
          greaterThan(0),
          reason:
              '${AppCopy.weekdayNames[i]} and ${AppCopy.weekdayNames[i + 1]} '
              'touch at ${scale}x — the strip reads as one word',
        );
      }
    });
  }

  testWidgets('and they are still in order, left to right', (tester) async {
    await pump(tester, 2);
    final rects = weekdayRects(tester);
    for (var i = 0; i < rects.length - 1; i++) {
      expect(rects[i].left, lessThan(rects[i + 1].left));
    }
  });
}
