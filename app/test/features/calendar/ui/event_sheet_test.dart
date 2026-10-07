import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/calendar/ui/event_sheet.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/pump_kit.dart';

/// The sheet every calendar event is made and changed in — the largest file in
/// the app, and it was at three covered lines.
///
/// What it decides matters: whether an event carries a wall-clock time or no
/// time at all, whether moving the start drags the end with it, and whether
/// "skip this one" is even offered.
void main() {
  final today = CalendarDate.parse('2026-09-18');

  late EventDraft? result;

  /// This sheet is taller than the viewport, and a tap on something below the
  /// fold silently lands on whatever is at that point instead.
  Future<void> tapInSheet(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Finder fieldLabelled(String label) => find.descendant(
    of: find.ancestor(
      of: find.text(label),
      matching: find.byType(NestTextField),
    ),
    matching: find.byType(TextField),
  );

  Future<void> open(
    WidgetTester tester, {
    HouseholdEvent? existing,
    bool canSkip = false,
  }) async {
    result = null;
    await pumpKit(
      tester,
      Builder(
        builder: (context) => NestButton(
          label: 'open',
          onPressed: () async {
            result = await showEventSheet(
              context: context,
              members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
              today: today,
              initialDate: today,
              existing: existing,
              canSkip: canSkip,
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  HouseholdEvent schoolRun({RecurrenceRule? recurrence}) => HouseholdEvent(
    id: 'e1',
    title: 'School run',
    date: today,
    startMinute: 450,
    endMinute: 510,
    recurrence: recurrence,
    memberIds: const [Fixtures.kidMemberId],
    createdBy: Fixtures.samMemberId,
  );

  testWidgets('a new event cannot be saved without a title', (tester) async {
    await open(tester);

    expect(find.text(AppCopy.calendarAddEvent), findsWidgets);
    final save = tester.widget<NestButton>(
      find.widgetWithText(NestButton, AppCopy.householdSave),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('a timed event comes back with wall-clock minutes', (
    tester,
  ) async {
    await open(tester);

    await tester.enterText(
      fieldLabelled(AppCopy.calendarTitleLabel),
      'Parents evening',
    );
    await tester.pumpAndSettle();
    await tapInSheet(
      tester,
      find.widgetWithText(NestButton, AppCopy.householdSave),
    );

    final saved = result! as EventSaved;
    expect(saved.title, 'Parents evening');
    expect(saved.date, today);
    expect(
      saved.startMinute,
      isNotNull,
      reason: 'a timed event stores minutes, never an instant (ADR-0002)',
    );
    expect(saved.endMinute, isNotNull);
  });

  testWidgets('all day takes the times away entirely', (tester) async {
    await open(tester);

    await tester.enterText(
      fieldLabelled(AppCopy.calendarTitleLabel),
      'Kid off school',
    );
    await tester.pumpAndSettle();
    await tapInSheet(tester, find.text(AppCopy.calendarAllDay));
    await tapInSheet(
      tester,
      find.widgetWithText(NestButton, AppCopy.householdSave),
    );

    final saved = result! as EventSaved;
    expect(saved.startMinute, isNull);
    expect(
      saved.endMinute,
      isNull,
      reason: 'an all-day event has no time, not a time of midnight',
    );
  });

  testWidgets(
    'editing opens on the event it was given, and keeps who it is for',
    (tester) async {
      await open(tester, existing: schoolRun());

      expect(find.text(AppCopy.calendarEditEvent), findsWidgets);
      expect(
        tester
            .widget<TextField>(fieldLabelled(AppCopy.calendarTitleLabel))
            .controller
            ?.text,
        'School run',
      );

      await tapInSheet(
        tester,
        find.widgetWithText(NestButton, AppCopy.householdSave),
      );

      expect(
        (result! as EventSaved).memberIds,
        [Fixtures.kidMemberId],
        reason: 'saving without touching the picker must not empty it',
      );
    },
  );

  testWidgets('who it is for can be changed to everyone', (tester) async {
    await open(tester, existing: schoolRun());

    await tapInSheet(tester, find.text(AppCopy.calendarEveryone));
    await tapInSheet(
      tester,
      find.widgetWithText(NestButton, AppCopy.householdSave),
    );

    expect(
      (result! as EventSaved).memberIds,
      isEmpty,
      reason: 'everyone is the empty list, and is a real answer',
    );
  });

  testWidgets('deleting comes back as its own answer, not as a save', (
    tester,
  ) async {
    await open(tester, existing: schoolRun());

    await tapInSheet(
      tester,
      find.widgetWithText(NestButton, AppCopy.householdRemove),
    );

    expect(result, isA<EventDeleted>());
  });

  group('skipping one occurrence', () {
    testWidgets('is not offered on an event that happens once', (tester) async {
      await open(tester, existing: schoolRun());
      expect(find.text(AppCopy.calendarSkip), findsNothing);
    });

    testWidgets('is offered on a repeating one, and is its own answer', (
      tester,
    ) async {
      await open(
        tester,
        existing: schoolRun(
          recurrence: const RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            weekdays: [5],
          ),
        ),
        canSkip: true,
      );

      await tapInSheet(
        tester,
        find.widgetWithText(NestButton, AppCopy.calendarSkip),
      );

      expect(result, isA<EventSkipped>());
    });
  });

  testWidgets('closing without saving answers nothing', (tester) async {
    await open(tester);
    Navigator.of(tester.element(find.byType(NestTextField).first)).pop();
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
