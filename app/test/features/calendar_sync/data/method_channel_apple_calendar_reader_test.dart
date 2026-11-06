import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar_sync/data/method_channel_apple_calendar_reader.dart';
import 'package:nestprep/features/calendar_sync/model/apple_calendar.dart';

void main() {
  group('what the iPhone sends', () {
    test('a timed occurrence, in the payload shape the server takes', () {
      final occurrence = MethodChannelAppleCalendarReader.occurrenceFrom({
        'id': 'ev@1793000000',
        'title': 'Dentist',
        'allDay': false,
        'start': 1793000000000,
        'end': 1793003600000,
      });
      expect(occurrence, isA<TimedAppleOccurrence>());
      expect(occurrence!.toPayload(), {
        'id': 'ev@1793000000',
        'title': 'Dentist',
        'allDay': false,
        'start': 1793000000000,
        'end': 1793003600000,
      });
    });

    test('an all-day occurrence keeps its dates', () {
      final occurrence = MethodChannelAppleCalendarReader.occurrenceFrom({
        'id': 'half-term@1',
        'title': 'Half term',
        'allDay': true,
        'startDate': '2026-11-09',
        'endDateExclusive': '2026-11-14',
      });
      expect(occurrence?.toPayload(), {
        'id': 'half-term@1',
        'title': 'Half term',
        'allDay': true,
        'startDate': '2026-11-09',
        'endDateExclusive': '2026-11-14',
      });
    });

    test('drops anything malformed rather than failing the whole read', () {
      for (final raw in <Object?>[
        null,
        'text',
        {'title': 'no id', 'allDay': false, 'start': 1, 'end': 2},
        {'id': 'x', 'title': 'no times', 'allDay': false},
        {'id': 'x', 'title': 'bad date', 'allDay': true, 'startDate': '9/11'},
      ]) {
        expect(MethodChannelAppleCalendarReader.occurrenceFrom(raw), isNull);
      }
    });

    test('calendars, with birthdays and subscriptions not suggested', () {
      final calendar = MethodChannelAppleCalendarReader.calendarFrom({
        'id': 'c1',
        'title': 'Birthdays',
        'account': 'Other',
        'suggested': false,
      });
      expect(calendar?.suggested, isFalse);
      expect(calendar?.account, 'Other');
      expect(MethodChannelAppleCalendarReader.calendarFrom({'id': ''}), isNull);
    });

    test('an access answer it does not know reads as refused', () {
      expect(
        MethodChannelAppleCalendarReader.accessFrom('granted'),
        AppleCalendarAccess.granted,
      );
      expect(
        MethodChannelAppleCalendarReader.accessFrom('somethingNew'),
        AppleCalendarAccess.denied,
      );
    });
  });

  test(
    'a phone that is not an iPhone reads nothing and asks nothing',
    () async {
      const android = MethodChannelAppleCalendarReader(isAvailable: false);
      expect(await android.access(), AppleCalendarAccess.restricted);
      expect(await android.calendars(), isEmpty);
      expect(
        await android.occurrences(
          calendarIds: ['c'],
          from: DateTime(2026),
          to: DateTime(2027),
        ),
        isEmpty,
      );
    },
  );
}
