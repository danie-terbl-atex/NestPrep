import '../model/apple_calendar.dart';

/// The calendars on this iPhone, read through EventKit. Read-only: nothing
/// here can change a calendar.
abstract interface class AppleCalendarReader {
  /// False on a phone that has no Apple calendars to read — Android.
  bool get isAvailable;

  Future<AppleCalendarAccess> access();

  /// Asks once; after a refusal only Settings can change it.
  Future<AppleCalendarAccess> requestAccess();

  Future<List<AppleCalendar>> calendars();

  Future<List<AppleOccurrence>> occurrences({
    required List<String> calendarIds,
    required DateTime from,
    required DateTime to,
  });

  Future<void> openSettings();
}
