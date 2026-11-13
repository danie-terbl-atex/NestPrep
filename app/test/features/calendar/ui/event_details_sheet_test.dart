import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/calendar/model/event_occurrence.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/calendar/ui/event_details_sheet.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/pump_kit.dart';

void main() {
  final today = CalendarDate.parse('2026-09-18');

  late bool? wantsEdit;

  HouseholdEvent birthday({String? note, RecurrenceRule? recurrence}) =>
      HouseholdEvent(
        id: 'e1',
        title: 'Mia’s birthday party',
        note: note,
        date: today,
        startMinute: 14 * 60,
        endMinute: 17 * 60,
        recurrence: recurrence,
        memberIds: const [Fixtures.kidMemberId],
        createdBy: Fixtures.samMemberId,
      );

  Future<void> open(
    WidgetTester tester,
    HouseholdEvent event, {
    bool canEdit = true,
    List<Member>? members,
    Brightness brightness = Brightness.light,
  }) async {
    wantsEdit = null;
    await pumpKit(
      tester,
      brightness: brightness,
      Builder(
        builder: (context) => NestButton(
          label: 'open',
          onPressed: () async {
            wantsEdit = await showEventDetailsSheet(
              context: context,
              occurrence: EventOccurrence(event: event, date: today),
              members: members ?? [Fixtures.kid],
              today: today,
              canEdit: canEdit,
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows what, when, who and the notes', (tester) async {
    await open(tester, birthday(note: 'Gift request: a horse'));

    expect(find.text('Mia’s birthday party'), findsOneWidget);
    expect(find.text('14:00 – 17:00'), findsOneWidget);
    expect(find.text(Fixtures.kid.displayName), findsOneWidget);
    expect(find.text(AppCopy.calendarNotesLabel), findsOneWidget);
    expect(find.text('Gift request: a horse'), findsOneWidget);
  });

  testWidgets('without notes, there is no notes card', (tester) async {
    await open(tester, birthday());
    expect(find.text(AppCopy.calendarNotesLabel), findsNothing);
  });

  testWidgets('a repeating event says how often', (tester) async {
    await open(
      tester,
      birthday(
        recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.weekly),
      ),
    );
    expect(find.text(AppCopy.repeatWeekly), findsOneWidget);
  });

  testWidgets('Edit answers that they want to change it', (tester) async {
    await open(tester, birthday());
    await tester.tap(find.text(AppCopy.calendarEditEvent));
    await tester.pumpAndSettle();
    expect(wantsEdit, isTrue);
  });

  testWidgets('without edit, it can be read and not changed', (tester) async {
    await open(tester, birthday(note: 'Gift request: a horse'), canEdit: false);
    expect(find.text('Gift request: a horse'), findsOneWidget);
    expect(find.text(AppCopy.calendarEditEvent), findsNothing);

    Navigator.of(tester.element(find.text('Mia’s birthday party'))).pop();
    await tester.pumpAndSettle();
    expect(wantsEdit, isFalse);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await open(
      tester,
      birthday(
        note: 'Gift request: a horse. ${'Bring a jersey, it gets cold. ' * 8}',
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          weekdays: [1, 3, 5],
        ),
      ),
      members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
      brightness: Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
}
