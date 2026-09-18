import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/recurrence/recurrence_expansion.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/ui/recurrence_editor.dart';

import '../../support/pump_kit.dart';

/// Choosing when a repeat stops.
///
/// The model has carried `until` since the beginning, the expansion has always
/// honoured it, `AppCopy` has held the words for it, and the calendar phase
/// listed an end date as in scope — and no control ever set it. The editor even
/// preserved the value faithfully through every other change, which is what
/// made it invisible: everything worked except the part that asks.
void main() {
  final firstDate = CalendarDate.parse('2026-09-18');

  late RecurrenceRule? rule;

  Future<void> pump(WidgetTester tester, {RecurrenceRule? initial}) async {
    rule = initial;
    await pumpKit(
      tester,
      StatefulBuilder(
        builder: (context, setState) => RecurrenceEditor(
          rule: rule,
          firstDate: firstDate,
          onChanged: (next) => setState(() => rule = next),
        ),
      ),
    );
  }

  testWidgets('a thing that does not repeat is not asked when it stops', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(AppCopy.repeatForever), findsNothing);
  });

  testWidgets('a repeating thing repeats forever until it is told not to', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text(AppCopy.repeatWeekly));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.repeatForever), findsOneWidget);
    expect(rule?.until, isNull, reason: 'forever is the default');
  });

  testWidgets('choosing an end gives it one, and it is after the start', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text(AppCopy.repeatWeekly));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NestChip, AppCopy.repeatUntilLabel));
    await tester.pumpAndSettle();

    expect(rule?.until, isNotNull);
    expect(
      rule!.until!.isAfter(firstDate),
      isTrue,
      reason: 'an end before the start is a rule with no occurrences',
    );
  });

  testWidgets('and changing its mind back clears it', (tester) async {
    await pump(
      tester,
      initial: RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        weekdays: const [5],
        until: CalendarDate.parse('2026-12-31'),
      ),
    );

    await tester.tap(find.widgetWithText(NestChip, AppCopy.repeatForever));
    await tester.pumpAndSettle();

    expect(
      rule?.until,
      isNull,
      reason: 'copyWith cannot put a null back, which is why withNoEnd exists',
    );
    expect(rule?.frequency, RecurrenceFrequency.weekly);
    expect(rule?.weekdays, [5], reason: 'clearing the end keeps the rest');
  });

  testWidgets('an end date survives a change of frequency', (tester) async {
    await pump(
      tester,
      initial: RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        until: CalendarDate.parse('2026-12-31'),
      ),
    );

    await tester.tap(find.text(AppCopy.repeatMonthly));
    await tester.pumpAndSettle();

    expect(rule?.frequency, RecurrenceFrequency.monthly);
    expect(rule?.until, CalendarDate.parse('2026-12-31'));
  });

  test('and the expansion stops there, which is the whole point', () {
    final until = CalendarDate.parse('2026-10-09');
    final days = expandOccurrences(
      firstDate: firstDate,
      rule: RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        weekdays: [firstDate.weekday],
        until: until,
      ),
      windowStart: firstDate,
      windowEnd: CalendarDate.parse('2026-11-30'),
    );

    expect(days, isNotEmpty);
    expect(
      days.every((day) => !day.isAfter(until)),
      isTrue,
      reason: 'nothing may fall after the day it was told to stop',
    );
  });
}
